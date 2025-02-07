`ifndef keyExpan_v
`define keyExpan_v
`include "subByte.v"

module keyExpan ( // clk, en, round, input_key , round_key 
    input  clk,
    input  en,
    input [3:0] round,
    input  [127:0] input_key,
    output [127:0] round_key
);


reg [3:0] round_nm = 0 ;
reg [127:0] round_key_new , old_round_key;
reg done = 0;


reg [1:0] state = 2'b00;
reg [1:0] next_state = 2'b00;

reg [128*11 - 1:0] key_reg;
reg [31:0]circ , circSub , xored ;
reg [31:0] subByteIn ;
wire [31:0] subByteOut;
reg [31:0] sbo ;
reg [31:0] rc_check ;
localparam idle = 2'b00;
localparam main = 2'b01;
reg [127:0]save = 128'hx;

subByte sb_inst(subByteIn , subByteOut) ;

assign round_key = (round >= 0 && round <= 10) ? key_reg[128*(round+1) - 1 -: 128] : 128'hx ;


always @(posedge clk) begin
    if(en == 0) begin
        round_key_new <= 128'hx;
        round_nm <= 0;
        done <= 0;
    end else begin
        case(state)
            idle: begin
                state <= next_state;
                round_nm <= (done) ? 0 : 1 ;
                sbo <= subByteOut;
            end
            main: begin
                state <= (round_nm == 10) ? idle : main;
                done <= (round_nm == 10) ? 1 : 0;
                round_nm <= (round_nm == 10) ? 0 : round_nm + 1;
                sbo <= subByteOut;
                save <= (round_nm == 2) ? key_reg[128*(2) - 1 -: 128] : save;
            end
            default : state <= idle;
        endcase
    end
end

always @ * begin
     case(state)
     idle : begin
          if(en)begin
               key_reg[128*(round_nm + 1) - 1 -: 128] = input_key ;
               old_round_key = input_key ; 
               circ = {input_key[23:0] , input_key[31 -: 8]} ;
               subByteIn = circ ;
               next_state = main ;
          end
          else begin end
     end
     main : begin
     if(en) begin
                  rc_check = round_cf(round_nm) ;
          circSub =  sbo ;
          xored = circSub ^ round_cf(round_nm) ;
          round_key_new[127 -: 32] = old_round_key[127 -: 32] ^ xored ;
          round_key_new[127 - 32 -: 32] = old_round_key[127 - 32 -: 32] ^  round_key_new[127 -: 32];
          round_key_new[127 - 2*32 -: 32] = old_round_key[127 - 2*32 -: 32] ^ round_key_new[127 - 32 -: 32] ;
          round_key_new[127 - 3*32 -: 32] = old_round_key[127 - 3*32 -: 32] ^ round_key_new[127 - 2*32 -: 32] ;
          old_round_key = round_key_new ;
          key_reg[128*(round_nm + 1) - 1 -: 128] = round_key_new ;
          circ = {round_key_new[23:0] , round_key_new[31 -: 8]} ;
          subByteIn = circ ;       
     end
     else begin end

     end
     default : ;
     endcase
end

function automatic [31:0]round_cf(input [3:0] r);
 case(r)
    4'h1: round_cf=32'h01000000;
    4'h2: round_cf=32'h02000000;
    4'h3: round_cf=32'h04000000;
    4'h4: round_cf=32'h08000000;
    4'h5: round_cf=32'h10000000;
    4'h6: round_cf=32'h20000000;
    4'h7: round_cf=32'h40000000;
    4'h8: round_cf=32'h80000000;
    4'h9: round_cf=32'h1b000000;
    4'ha: round_cf=32'h36000000;
    default: round_cf=32'h00000000;
  endcase
endfunction
endmodule
`endif