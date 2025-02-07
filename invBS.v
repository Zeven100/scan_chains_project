`ifndef INVBS_V
`define INVBS_V
`include "invsbox.v"
module invBS (
     input [127:0]in , 
     output[127:0] out 
);
     invsbox invSB_inst_1(in[127 -: 32] , out[127 -: 32]) ;
     invsbox invSB_inst_2(in[95 -: 32] , out[95 -: 32]) ;
     invsbox invSB_inst_3(in[63 -: 32] , out[63 -: 32]) ;
     invsbox invSB_inst_4(in[31 -: 32] , out[31 -: 32]) ;

endmodule
`endif