`include "encrypt.v"
`include "keyExpan.v"

module dtb();
    reg clk, e_en, ke_en;
    wire [127:0] e_ciphertext , ke_round_key;
    reg [127:0] e_plaintext ;
    wire [3:0] e_round;
    reg [127:0] e_round_key;

    reg [127:0] input_key;
    reg [3:0] ke_round;
    

    encrypt dut(clk , e_en , e_plaintext , e_ciphertext , e_round , e_round_key);
    keyExpan ke_inst(clk, ke_en, ke_round, input_key, ke_round_key);

    always #5 clk = ~clk;

    always @* begin
        ke_round = e_round;
        e_round_key = ke_round_key;
    end

    initial begin
        clk = 0;
        e_en = 0;
        ke_en = 0;

        input_key =     128'h2b7e151628aed2a6abf7158809cf4f3c;
        e_plaintext =   128'h00000000000000000000000000000002;
        ke_en = 1;

        #110 e_en = 1;ke_en = 0;
        #120 e_en = 0;
        $stop ;
    end

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, dtb);
    end
endmodule