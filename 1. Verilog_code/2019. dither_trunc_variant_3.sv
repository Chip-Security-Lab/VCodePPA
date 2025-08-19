//SystemVerilog
// Top-level module: Dithered Truncation with Hierarchical Structure

module dither_trunc #(parameter W=16) (
    input  [W+3:0] in,
    output [W-1:0] out
);

    // Internal signals
    wire [2:0] lfsr_out;
    wire [3:0] trunc_bits;
    wire [W-1:0] trunc_high;
    wire        cmp_result;
    wire [3:0]  add_in_b;
    wire [3:0]  prefix_sum;

    // LFSR: 3-bit Linear Feedback Shift Register for dithering
    dither_lfsr u_lfsr (
        .clk_in         (in),           // LFSR updated on input change for compatibility
        .lfsr_out       (lfsr_out)
    );

    // Extract truncation bits and high bits
    assign trunc_bits = in[3:0];
    assign trunc_high = in[W+3:4];

    // Compare truncation bits with LFSR output
    dither_cmp u_cmp (
        .trunc_bits     (trunc_bits),
        .lfsr_val       (lfsr_out),
        .cmp_result     (cmp_result)
    );

    // Prepare adder input
    assign add_in_b = {3'b000, cmp_result};

    // 4-bit Parallel Prefix Adder (Kogge-Stone)
    dither_prefix_adder4 u_prefix_adder (
        .a              (trunc_high[3:0]),
        .b              (add_in_b),
        .sum            (prefix_sum)
    );

    // Output assignment: concatenate high bits and adder sum
    assign out = {trunc_high[W-1:4], prefix_sum};

endmodule

// ----------------------------------------------------------
// 3-bit LFSR Module (Dither Generator)
// ----------------------------------------------------------
module dither_lfsr (
    input  [19:0] clk_in, // Accepts vector for event sensitivity (matches original code)
    output reg [2:0] lfsr_out
);
    // LFSR initialization
    initial begin
        lfsr_out = 3'b101;
    end

    // LFSR update on any change of clk_in (matches original always @(in))
    always @(clk_in) begin
        lfsr_out <= {lfsr_out[1:0], lfsr_out[2] ^ lfsr_out[1]};
    end
endmodule

// ----------------------------------------------------------
// 4-bit Comparator Module
// ----------------------------------------------------------
module dither_cmp (
    input  [3:0] trunc_bits,
    input  [2:0] lfsr_val,
    output       cmp_result
);
    // Compares if trunc_bits > lfsr_val (zero-extended)
    assign cmp_result = (trunc_bits > {1'b0, lfsr_val});
endmodule

// ----------------------------------------------------------
// 4-bit Parallel Prefix Adder (Kogge-Stone) Module
// ----------------------------------------------------------
module dither_prefix_adder4 (
    input  [3:0] a,
    input  [3:0] b,
    output [3:0] sum
);
    // Generate and Propagate signals
    wire [3:0] g, p;
    wire [3:0] g1, p1, g2, p2;
    wire [3:0] c;

    assign g = a & b;
    assign p = a ^ b;

    // Stage 1
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];

    // Stage 2
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];

    // Carry signals
    assign c[0] = 1'b0;
    assign c[1] = g2[0];
    assign c[2] = g2[1];
    assign c[3] = g2[2];

    // Sum calculation
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
endmodule