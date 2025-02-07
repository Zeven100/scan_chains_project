`ifndef BYTE_SUB_V
`define BYTE_SUB_V

`include "subByte.v"
module byteSub ( // 
     input [127:0] in ,
     output [127:0] out 
);

wire [127:0]bs_out ;

subByte s0(in[31 -: 32] , out[31 -: 32]) ; 
subByte s1(in[63 -: 32] ,out[63 -: 32]); 
subByte s2(in[95 -: 32] , out[95 -: 32]) ; 
subByte s3(in[127 -: 32] , out[127 -: 32]) ; 
     
endmodule
`endif