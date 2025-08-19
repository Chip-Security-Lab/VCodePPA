//SystemVerilog
module tausworthe_rng (
    input  wire        clk_in,
    input  wire        rst_in,
    output wire [31:0] rnd_out
);
    reg [31:0] state1, state2, state3;

    // Precompute shifts and XORs to balance logic depth
    wire [31:0] state1_shifted, state2_shifted, state3_shifted;
    wire [31:0] state1_xored, state2_xored, state3_xored;
    wire [31:0] state1_b, state2_b, state3_b;

    // Parallelize shift and xor for state1
    assign state1_shifted = state1 << 13;
    assign state1_xored   = state1 ^ state1_shifted;
    assign state1_b       = state1_xored >> 19;
    // Parallelize shift and xor for state2
    assign state2_shifted = state2 << 2;
    assign state2_xored   = state2 ^ state2_shifted;
    assign state2_b       = state2_xored >> 25;
    // Parallelize shift and xor for state3
    assign state3_shifted = state3 << 3;
    assign state3_xored   = state3 ^ state3_shifted;
    assign state3_b       = state3_xored >> 11;

    // Precompute masks to minimize logic depth
    localparam [31:0] MASK1 = 32'hFFFFFFFE;
    localparam [31:0] MASK2 = 32'hFFFFFFF8;
    localparam [31:0] MASK3 = 32'hFFFFFFF0;

    wire [31:0] state1_masked, state2_masked, state3_masked;
    assign state1_masked = state1 & MASK1;
    assign state2_masked = state2 & MASK2;
    assign state3_masked = state3 & MASK3;

    // Optimized next state computation using conditional range check
    wire s1_in_range, s2_in_range, s3_in_range;
    assign s1_in_range = (state1 >= 32'h80000000) ? 1'b1 : 1'b0;
    assign s2_in_range = (state2 >= 32'h80000000) ? 1'b1 : 1'b0;
    assign s3_in_range = (state3 >= 32'h80000000) ? 1'b1 : 1'b0;

    wire [31:0] next_state1, next_state2, next_state3;

    assign next_state1 = s1_in_range ? (state1_masked ^ state1_b) : (state1_masked ^ state1_b);
    assign next_state2 = s2_in_range ? (state2_masked ^ state2_b) : (state2_masked ^ state2_b);
    assign next_state3 = s3_in_range ? (state3_masked ^ state3_b) : (state3_masked ^ state3_b);

    always @(posedge clk_in) begin
        if (rst_in) begin
            state1 <= 32'h1;
            state2 <= 32'h2;
            state3 <= 32'h4;
        end else begin
            state1 <= next_state1;
            state2 <= next_state2;
            state3 <= next_state3;
        end
    end

    // Balanced final output computation
    assign rnd_out = (state1 ^ state2) ^ state3;

endmodule