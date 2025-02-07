`include "decrypt.v"
`include "keyExpan.v"

module dtb();
    reg clk, d_en, ke_en;
    reg [127:0] d_cypherText;
    wire [127:0] d_plainText , ke_round_key;
    wire [3:0] d_round;
    reg [127:0] d_round_key;

    reg [127:0] input_key;
    reg [3:0] ke_round;
    wire dn ;

    decrypt dut(clk, d_en, d_cypherText, d_plainText, d_round, d_round_key , dn);
    keyExpan ke_inst(clk, ke_en, ke_round, input_key, ke_round_key);

    always #5 clk = ~clk;

    always @* begin
        ke_round = d_round;
        d_round_key = ke_round_key;
    end

    initial begin
        clk = 0;
        d_en = 0;
        ke_en = 0;

        input_key = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        d_cypherText = 128'h973f2ef34879e2027f1734303ff21f89;
        ke_en = 1;

        #110 d_en = 1;ke_en = 0;
        #120 d_en = 0;
        $stop ;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, dtb);
    end
endmodule