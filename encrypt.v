`ifndef encrypt_v
`define encrypt_v
`include "byteSub.v"
module encrypt ( // clk , en , plaintext , ciphertext , round , round_key
    input clk , en , 
    input [127:0] plaintext ,
    output reg [127:0] ciphertext ,
    output [3:0] round ,
    input [127:0] round_key ,
    output reg dn
);

parameter [1:0]idle = 2'b00 , main = 2'b01 , final = 2'b10 ;
reg [1:0] state = idle , next_state = idle ;
reg [3:0] round_nm = 4'bx;
reg done = 0 ;
assign round = round_nm ;
reg [127:0] old_block ;  
reg [127:0]KAOut , SROut , MCOut ;
wire [127:0]byteSubOut ;
byteSub bs_inst(KAOut , byteSubOut) ;


always @(posedge clk)begin
    if(en == 0)begin
        state <= idle ;
        round_nm <= 4'b0 ;
        dn <= 0 ;
        done <= 0 ;
        old_block <= 128'hx ;
    end
    else begin
        case(state)
        idle : begin
            state <= done ? idle : main ;
            round_nm <= done ? 0 : 1 ;
            old_block <= byteSubOut ;
            dn <= 0 ;

        end
        main : begin
            state <= (round_nm == 9) ? final : main ; 
            round_nm <= (round_nm == 9) ? 10 : round_nm + 1 ;
            done <= 0 ;
            old_block <= byteSubOut ;
            dn <= 0 ;
        end
        final : begin
            state <= idle ;
            dn <= 1 ;
            done <= 1 ;
        end
        endcase
    end
end
always @(*)begin
    case(state)
    idle : begin
        KAOut = addKey(plaintext , round_key) ;
    end
    main : begin
        SROut = shiftrows(old_block) ;
        MCOut = mixcolumns(SROut) ;
        KAOut = addKey(MCOut , round_key) ;
    end
    final : begin
        SROut = shiftrows(old_block) ;
        KAOut = addKey(SROut , round_key) ;
        ciphertext = KAOut ;
        dn = 1 ;
    end
    endcase
end
////////////////////////////////////------------------------------------------------
////////////////////////////////////------------------------------------------------

function automatic [127 : 0] shiftrows(input [127 : 0] data);
    reg [31 : 0] w0, w1, w2, w3;
    reg [31 : 0] ws0, ws1, ws2, ws3;
    begin
      w0 = data[127 : 096];
      w1 = data[095 : 064];
      w2 = data[063 : 032];
      w3 = data[031 : 000];

      ws0 = {w0[31 : 24], w1[23 : 16], w2[15 : 08], w3[07 : 00]};
      ws1 = {w1[31 : 24], w2[23 : 16], w3[15 : 08], w0[07 : 00]};
      ws2 = {w2[31 : 24], w3[23 : 16], w0[15 : 08], w1[07 : 00]};
      ws3 = {w3[31 : 24], w0[23 : 16], w1[15 : 08], w2[07 : 00]};

      shiftrows = {ws0, ws1, ws2, ws3};
    end
  endfunction // shiftrows
     


function automatic [127:0]addKey(input [127:0]in ,input[127:0]key );
     addKey = in ^ key ;
endfunction

function automatic [31:0]mixw(input [31:0]w) ;
begin :mixw
     reg [7 : 0] b0, b1, b2, b3;
    reg [7 : 0] mb0, mb1, mb2, mb3;
    begin
      b0 = w[31 : 24];
      b1 = w[23 : 16];
      b2 = w[15 : 08];
      b3 = w[07 : 00];

      mb0 = gm2(b0) ^ gm3(b1) ^ b2      ^ b3;
      mb1 = b0      ^ gm2(b1) ^ gm3(b2) ^ b3;
      mb2 = b0      ^ b1      ^ gm2(b2) ^ gm3(b3);
      mb3 = gm3(b0) ^ b1      ^ b2      ^ gm2(b3);

      mixw = {mb0, mb1, mb2, mb3};
end
end
endfunction

function automatic [127 : 0] mixcolumns(input [127 : 0] data);
    reg [31 : 0] w0, w1, w2, w3;
    reg [31 : 0] ws0, ws1, ws2, ws3;
    begin
      w0 = data[127 : 096];
      w1 = data[095 : 064];
      w2 = data[063 : 032];
      w3 = data[031 : 000];

      ws0 = mixw(w0);
      ws1 = mixw(w1);
      ws2 = mixw(w2);
      ws3 = mixw(w3);

      mixcolumns = {ws0, ws1, ws2, ws3};
    end
  endfunction // mixcolumns


// Multiply by 2 in GF(2^8) for AES
    function [7:0] gm2;
        input [7:0] x;
        begin
            if (x[7] == 1) 
                gm2 = (x << 1) ^ 8'h1b; // x * 2 in GF(2^8)
            else 
                gm2 = x << 1;
        end
    endfunction

    // Multiply by 3 in GF(2^8) for AES
    function [7:0] gm3;
        input [7:0] x;
        begin
            gm3 = gm2(x) ^ x; // x * 3 = (x * 2) + x
        end
    endfunction
    
endmodule
`endif