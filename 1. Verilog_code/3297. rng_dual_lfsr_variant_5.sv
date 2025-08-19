//SystemVerilog
module rng_dual_lfsr_17(
    input            clk,
    input            rst,
    output reg [7:0] rnd
);
    reg [7:0] lfsr_a, lfsr_b;
    reg [7:0] next_lfsr_a, next_lfsr_b;
    reg [7:0] xor_result;

    // Optimized feedback signal computation using reduction XOR and masking
    wire feedback_a = ^(lfsr_a & 8'b10100000); // lfsr_a[7] ^ lfsr_a[5]
    wire feedback_b = lfsr_b[6] ^ lfsr_b[0];

    always @* begin
        // Efficient next state computation for LFSRs
        next_lfsr_a = {lfsr_a[6:0], feedback_b};
        next_lfsr_b = {lfsr_b[6:0], feedback_a};
        xor_result  = next_lfsr_a ^ next_lfsr_b;
    end

    always @(posedge clk) begin
        if (rst) begin
            lfsr_a <= 8'hF3;
            lfsr_b <= 8'h0D;
            rnd    <= 8'hF3 ^ 8'h0D;
        end else begin
            lfsr_a <= next_lfsr_a;
            lfsr_b <= next_lfsr_b;
            rnd    <= xor_result;
        end
    end
endmodule