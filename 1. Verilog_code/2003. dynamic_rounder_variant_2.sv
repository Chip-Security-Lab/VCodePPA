//SystemVerilog
module dynamic_rounder #(parameter W=16) (
    input  wire [W+2:0] in,
    input  wire         mode,
    output reg  [W-1:0] out
);

wire [W-1:0] unrounded_value;
wire         has_low_bits;
wire [W-1:0] rounded_value;

assign unrounded_value = in[W+2:3];
assign has_low_bits    = |in[2:0];

kogge_stone_adder_3bit kogge_stone_adder_inst (
    .a      (unrounded_value[2:0]),
    .b      ({2'b00, has_low_bits}),
    .sum    (rounded_value[2:0]),
    .cout   ()
);

generate
    if (W > 3) begin : GEN_HIGH_BITS_ASSIGN
        assign rounded_value[W-1:3] = unrounded_value[W-1:3];
    end
endgenerate

always @(*) begin
    if (mode) begin
        out = rounded_value;
    end else begin
        out = unrounded_value;
    end
end

endmodule

module kogge_stone_adder_3bit (
    input  wire [2:0] a,
    input  wire [2:0] b,
    output wire [2:0] sum,
    output wire       cout
);
    wire [2:0] g, p;
    wire [2:0] c;

    // Generate and Propagate
    assign g = a & b;
    assign p = a ^ b;

    // Stage 1
    wire g1_0, p1_0, g2_1, p2_1;
    assign g1_0 = g[1] | (p[1] & g[0]);
    assign p1_0 = p[1] & p[0];
    assign g2_1 = g[2] | (p[2] & g[1]);
    assign p2_1 = p[2] & p[1];

    // Stage 2
    wire g2_0;
    assign g2_0 = g2_1 | (p2_1 & g[0]);

    // Carry chain
    assign c[0] = 1'b0;
    assign c[1] = g[0];
    assign c[2] = g1_0;

    // Sum and Cout
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign cout   = g2_0;

endmodule