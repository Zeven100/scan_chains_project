`include "keyExpan.v"
`include "clb.v"
`include "decrypt.v"
`include "encrypt.v"

module top (
    input        clk,
    input        tdi,
    input        tms,
    input        trst,
    input  [127:0] input_key,
    input  [127:0] a, b,
    output [127:0] c,
    output reg   tdo
);

    // FSM state definitions.
    parameter [3:0] normal  = 4'b0000,
                    idle    = 4'b0001,
                    serial  = 4'b0010,
                    capture = 4'b0011,
                    e       = 4'b0100,
                    d       = 4'b0101,
                    w1      = 4'b0110,
                    w2      = 4'b0111,
                    w3      = 4'b1000,
                    w4      = 4'b1001;

    // Instead of a 640–bit vector we use an array of 640 one–bit registers.
    // The overall chain is defined so that:
    //   bsc[639:512]  -> d_ciphertext
    //   bsc[511:384]  -> c_b
    //   bsc[383:256]  -> c_a
    //   bsc[255:128]  -> c_out
    //   bsc[127:0]    -> e_plaintext
    reg bsc [0:639];

    // Internal FSM state.
    reg [3:0] state = normal;

    // Signals to/from the CLB.
    reg [127:0] c_a, c_b;
    wire [127:0] c_out;
    assign c = c_out;

    // Key expansion signals.
    reg         ke_en  = 0;
    reg  [3:0]  ke_round;
    wire [127:0] round_key;

    // Signals for decryption and encryption.
    reg         d_en = 0, e_en = 0;
    reg [127:0] d_ciphertext, d_round_key;
    reg [127:0] e_plaintext, e_round_key;
    wire [3:0]  d_round, e_round;
    wire [127:0] d_plaintext, e_ciphertext;
    wire        d_dn, e_dn;

    keyExpan ke_inst(clk, ke_en, ke_round, input_key, round_key);
    clb      clb_inst(c_a, c_b, c_out);
    decrypt  d_inst(clk, d_en, d_ciphertext, d_plaintext, d_round, d_round_key, d_dn);
    encrypt  e_inst(clk, e_en, e_plaintext, e_ciphertext, e_round, e_round_key, e_dn);

    // Loop variable for for–loops.
    integer i;

    // Main sequential block.
    always @(posedge clk) begin
        if (~trst) begin
            // When trst is low, we reset:
            d_en   <= 0;
            e_en   <= 0;
            state  <= normal;
            ke_en  <= 1;
            // Reset all 640 bits in bsc.
            for (i = 0; i < 640; i = i + 1)
                bsc[i] <= 1'b0;
        end else begin
            // Default assignments for control signals.
            d_en   <= 0;
            e_en   <= 0;
            ke_en  <= 0;
            
            case (state)
                normal: begin
                    state <= idle;
                    ke_en <= 1; // wait a few cycles for key expansion initialization.
                end
                idle: begin
                    state <= (tms ? w1 : idle);
                end
                w1: begin
                    state <= (tms ? serial : w2);
                end
                w2: begin
                    state <= (tms ? capture : w3);
                end
                w3: begin
                    state <= (tms ? e : w4);
                end
                w4: begin
                    state <= (tms ? d : idle);
                end
                serial: begin
                    // Output the least–significant bit (bsc[0]) and shift the entire chain.
                    tdo <= bsc[0];
                    for (i = 0; i < 639; i = i + 1)
                        bsc[i] <= bsc[i+1];
                    bsc[639] <= tdi;
                    state <= (tms ? serial : idle);
                end
                capture: begin
                    state <= (tms ? capture : idle);
                    // Capture c_a from bits 256..383:
                    for (i = 0; i < 128; i = i + 1)
                        c_a[i] <= bsc[256 + i];
                    // Capture c_b from bits 384..511:
                    for (i = 0; i < 128; i = i + 1)
                        c_b[i] <= bsc[384 + i];
                    // Update c_out region: bits 128..255 are replaced with c_out.
                    for (i = 0; i < 128; i = i + 1)
                        bsc[128 + i] <= c_out[i];
                end
                e: begin
                    state <= (tms ? e : idle);
                    e_en <= 1;
                    // Load the e_plaintext from bits 0..127.
                    for (i = 0; i < 128; i = i + 1)
                        e_plaintext[i] <= bsc[i];
                    if (e_dn) begin
                        // When encryption is done, update bits 0..127 with the result.
                        for (i = 0; i < 128; i = i + 1)
                            bsc[i] <= e_ciphertext[i];
                    end
                end
                d: begin
                    state <= (tms ? d : idle);
                    d_en <= 1;
                    // Load the d_ciphertext from bits 512..639.
                    for (i = 0; i < 128; i = i + 1)
                        d_ciphertext[i] <= bsc[512 + i];
                    if (d_dn) begin
                        // When decryption is done, update bits 512..639 with the result.
                        for (i = 0; i < 128; i = i + 1)
                            bsc[512 + i] <= d_plaintext[i];
                    end
                end
                default: ; // do nothing
            endcase
        end
    end

    // A combinational block to select the appropriate key expansion round.
    always @* begin
        if (state == d) begin
            ke_round    = d_round;
            d_round_key = round_key;
        end else if (state == e) begin
            ke_round    = e_round;
            e_round_key = round_key;
        end
    end

endmodule
