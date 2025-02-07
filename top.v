
`include "keyExpan.v"
`include "clb.v"
`include "decrypt.v"
`include "encrypt.v"
module top ( // clk , tdi , tms , trst , input_key , a , b , c , tdo 
    input clk , tdi , tms , trst , 
    input [127:0] input_key, a, b  ,
    output [127:0] c , 
    output reg tdo 
);
///  when trst = 0 => normal mode operation of the clb , else fsm
parameter [3:0]normal = 4'b0000 , idle = 4'b0001 ,  serial = 4'b0010 , capture = 4'b0011 , e = 4'b0100 , d = 4'b0101 , w1 = 4'b0110 , w2 = 4'b0111 , w3 = 4'b1000 , w4 = 4'b1001 ;


//---------------------------------------------------------
reg [128*5 - 1 :0 ] bsc = 0 ; // boundary scan registers // 
// d_ciphertext -> bsc[128*5-1 -: 128] 
// c_b -> bsc[128*4 - 1 -: 128]
// c_a -> bsc[128*3 - 1 -: 128] 
// c_out -> bsc[128*2 - 1 -: 128]
// e_plaintext -> bsc[128*1 - 1 -: 128]
//----------------------------------------------------------

reg [3:0]state = normal ;


reg [127:0] c_a , c_b ;
wire [127:0] c_out ;
assign c = c_out ;


reg ke_en = 0 ;
reg [3:0]ke_round ;
wire [127:0]round_key ; 

reg d_en = 0 , e_en = 0 ;
reg [127:0] d_ciphertext , d_round_key , e_plaintext , e_round_key;
wire [3:0]d_round , e_round;
wire [127:0] d_plaintext , e_ciphertext ;
wire d_dn , e_dn ;
keyExpan ke_inst(clk, ke_en, ke_round, input_key , round_key ) ;
clb clb_inst(c_a , c_b , c_out) ;
decrypt d_inst(clk , d_en , d_ciphertext , d_plaintext , d_round, d_round_key , d_dn) ;
encrypt e_inst(clk , e_en , e_plaintext , e_ciphertext , e_round , e_round_key , e_dn ) ;


always @(posedge clk ) begin
    if(~trst)begin
        d_en <= 0 ;
        d_en <= 0 ;
        state <= normal ;
        ke_en <= 1 ;
    end
    else
    begin
    d_en <= 0 ;
    ke_en <= 0 ;
    e_en <= 0 ;
        case(state)
        
        normal : begin
            state <= idle ;
            ke_en <= 1 ; // need to wait 10 cycles at the start for the ke to be completed 
        end
        idle : 
        begin
            state <= tms ? w1 : idle ;
            ke_en <= 0; 
        end
        w1 : begin
            state <= tms ? serial : w2 ;
            ke_en <= 0 ;
        end
        w2 : begin
            state <= tms ? capture :  w3 ;
        end
        w3 : begin
            state <= tms ? e : w4 ;
        end
        w4 : begin
            state <= tms ? d : idle ;
        end
        serial : begin
            tdo <= bsc[0] ; 
            bsc <= {tdi , bsc[128*5 - 1 : 1]} ;
            state <= tms ? serial : idle ;

        end
        capture : begin
            state <= tms ? capture : idle ;
            c_a <= bsc[128*3 - 1 -: 128] ;
            c_b <= bsc[128*4 - 1 -: 128] ;
        end
        e : begin
            state <= tms ? e : idle ;
            e_en <= 1;
            if(e_dn) begin
              bsc [127:0] <= e_ciphertext ;
            end
        end
        d : begin
            state <= tms ? d : idle ;
            d_en <= 1 ;

        end
        default : ;
        endcase
    end
end

always @ * begin
    case(state)
    d : begin
        ke_round = d_round ;
        d_round_key = round_key ;
        d_ciphertext = bsc[128*5 - 1 -: 128] ;
        if(d_dn)begin
            bsc = {d_plaintext , bsc[128*4 - 1 : 0]} ;
        end
        else begin
        end
    end
    e : begin
        ke_round = e_round ;
        e_round_key = round_key ;
        e_plaintext = bsc[128*1 - 1 -: 128] ;
        if(e_dn)begin
            bsc[127:0] = e_ciphertext ;
        end
        else begin
        end
    end
    capture : begin
        bsc = {bsc[128*5 -1 -: 128 *3] , c_out , bsc [127 : 0]} ;
    end
    endcase
end
endmodule