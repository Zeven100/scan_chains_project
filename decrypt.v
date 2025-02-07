`ifndef _decrypt_v_
`define _decrypt_v_
`include "invBS.v"
module decrypt ( // clk , en , cypherText , plainText , round, round_key , dn
    input clk , en , 
    input [127 : 0] cipherText ,
    output reg [127 : 0] plainText ,
    output [3:0] round ,
    input [127 : 0] round_key ,
    output reg dn
);
parameter [1:0] idle = 2'b00 , first = 2'b01 , main = 2'b10 , final = 2'b11 ;
reg [1:0] state = idle ;
    
reg [3:0] round_nm = 4'bx ;
reg done_d = 0 , done = 0 ;
reg [127:0] old_block , KAOut , invSROut , invMCOut;
wire [127:0] invBSOut ;
assign round = round_nm ;
invBS ibs_inst(invSROut , invBSOut) ;

always @(posedge clk ) begin
    if(en == 0)begin
        state <= idle ;
        round_nm <= 4'bx ;
        done <= 0 ;
        dn <= 1'bx ;
        
    end
    else begin
        case(state)
            idle : begin
            state <= done ? idle : first ;  
            old_block <= cipherText ;  
            round_nm <= done ? 4'bx : 4'd10 ;
            dn <= 0 ;
            end
            first : begin
            state <= main ;
            old_block <= invBSOut ;
            round_nm <= 4'd9 ;
            end
            main : begin
            state <= (round_nm == 0) ? final : main ;
            done <= 0 ;
            round_nm <= (round_nm == 0 ) ? 0 : round_nm - 1 ;
            old_block <= invBSOut ;
            plainText <= (round_nm == 0) ? addroundkey(old_block , round_key) : plainText ;
            end  
            final : begin
            
            state <= idle ;
            done <= 1 ;
            round_nm <= 4'd10 ;
            plainText <= KAOut ;
            done_d <= 1 ;
            dn <= 1'b1 ;
            end
        endcase
         

    end
end
always @ * begin
    case(state)
        idle : begin
           round_nm = 4'd10 ;
        end
        first : begin
            KAOut = addroundkey(cipherText , round_key) ;
            invSROut = inv_shiftrows(KAOut) ;
            
        end
        main : begin
            KAOut = addroundkey(old_block , round_key) ;
            invMCOut = inv_mixcolumns(KAOut) ;
            invSROut = inv_shiftrows(invMCOut) ;
        end
        default : ;
    endcase
end

function automatic [7 : 0] gm2(input [7 : 0] op);
    begin
      gm2 = {op[6 : 0], 1'b0} ^ (8'h1b & {8{op[7]}});
    end
  endfunction // gm2

  function automatic [7 : 0] gm3(input [7 : 0] op);
    begin
      gm3 = gm2(op) ^ op;
    end
  endfunction // gm3

  function automatic [7 : 0] gm4(input [7 : 0] op);
    begin
      gm4 = gm2(gm2(op));
    end
  endfunction // gm4

  function automatic [7 : 0] gm8(input [7 : 0] op);
    begin
      gm8 = gm2(gm4(op));
    end
  endfunction // gm8

  function automatic [7 : 0] gm09(input [7 : 0] op);
    begin
      gm09 = gm8(op) ^ op;
    end
  endfunction // gm09

  function automatic [7 : 0] gm11(input [7 : 0] op);
    begin
      gm11 = gm8(op) ^ gm2(op) ^ op;
    end
  endfunction // gm11

  function automatic [7 : 0] gm13(input [7 : 0] op);
    begin
      gm13 = gm8(op) ^ gm4(op) ^ op;
    end
  endfunction // gm13

  function automatic [7 : 0] gm14(input [7 : 0] op);
    begin
      gm14 = gm8(op) ^ gm4(op) ^ gm2(op);
    end
  endfunction // gm14

  function automatic [31 : 0] inv_mixw(input [31 : 0] w);
    reg [7 : 0] b0, b1, b2, b3;
    reg [7 : 0] mb0, mb1, mb2, mb3;
    begin
      b0 = w[31 : 24];
      b1 = w[23 : 16];
      b2 = w[15 : 08];
      b3 = w[07 : 00];

      mb0 = gm14(b0) ^ gm11(b1) ^ gm13(b2) ^ gm09(b3);
      mb1 = gm09(b0) ^ gm14(b1) ^ gm11(b2) ^ gm13(b3);
      mb2 = gm13(b0) ^ gm09(b1) ^ gm14(b2) ^ gm11(b3);
      mb3 = gm11(b0) ^ gm13(b1) ^ gm09(b2) ^ gm14(b3);

      inv_mixw = {mb0, mb1, mb2, mb3};
    end
  endfunction // mixw

  function automatic [127 : 0] inv_mixcolumns(input [127 : 0] data);
    reg [31 : 0] w0, w1, w2, w3;
    reg [31 : 0] ws0, ws1, ws2, ws3;
    begin
      w0 = data[127 : 096];
      w1 = data[095 : 064];
      w2 = data[063 : 032];
      w3 = data[031 : 000];

      ws0 = inv_mixw(w0);
      ws1 = inv_mixw(w1);
      ws2 = inv_mixw(w2);
      ws3 = inv_mixw(w3);

      inv_mixcolumns = {ws0, ws1, ws2, ws3};
    end
  endfunction // inv_mixcolumns

  function automatic [127 : 0] inv_shiftrows(input [127 : 0] data);
    reg [31 : 0] w0, w1, w2, w3;
    reg [31 : 0] ws0, ws1, ws2, ws3;
    begin
      w0 = data[127 : 096];
      w1 = data[095 : 064];
      w2 = data[063 : 032];
      w3 = data[031 : 000];

      ws0 = {w0[31 : 24], w3[23 : 16], w2[15 : 08], w1[07 : 00]};
      ws1 = {w1[31 : 24], w0[23 : 16], w3[15 : 08], w2[07 : 00]};
      ws2 = {w2[31 : 24], w1[23 : 16], w0[15 : 08], w3[07 : 00]};
      ws3 = {w3[31 : 24], w2[23 : 16], w1[15 : 08], w0[07 : 00]};

      inv_shiftrows = {ws0, ws1, ws2, ws3};
    end
  endfunction // inv_shiftrows

  function automatic [127 : 0] addroundkey(input [127 : 0] data, input [127 : 0] rkey);
    begin
      addroundkey = data ^ rkey;
    end
  endfunction // addroundkey
endmodule
`endif