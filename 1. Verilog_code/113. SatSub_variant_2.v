// Comparator submodule to determine if a >= b
module Comparator(
    input [7:0] a,
    input [7:0] b,
    output reg greater_equal
);

always @(*) begin
    if (a >= b)
        greater_equal = 1'b1;
    else
        greater_equal = 1'b0;
end

endmodule

// Subtraction submodule
module Subtractor(
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff
);

assign diff = a - b;

endmodule

// Zero generator submodule
module ZeroGen(
    output [7:0] zero
);

assign zero = 8'h0;

endmodule

// Multiplexer submodule
module Mux(
    input [7:0] in0,
    input [7:0] in1,
    input sel,
    output reg [7:0] out
);

always @(*) begin
    if (sel)
        out = in0;
    else
        out = in1;
end

endmodule

// Top-level module
module SatSub(
    input [7:0] a,
    input [7:0] b,
    output [7:0] res
);

wire greater_equal;
wire [7:0] diff;
wire [7:0] zero;

// Instantiate submodules
Comparator comp_inst(
    .a(a),
    .b(b),
    .greater_equal(greater_equal)
);

Subtractor sub_inst(
    .a(a),
    .b(b),
    .diff(diff)
);

ZeroGen zero_inst(
    .zero(zero)
);

Mux mux_inst(
    .in0(diff),
    .in1(zero),
    .sel(greater_equal),
    .out(res)
);

endmodule