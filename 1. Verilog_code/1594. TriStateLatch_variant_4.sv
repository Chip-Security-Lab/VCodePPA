//SystemVerilog
// Latch core module
module LatchCore #(parameter BITS=8) (
    input clk,
    input [BITS-1:0] d,
    output reg [BITS-1:0] q
);
    always @(posedge clk) begin
        q <= d;
    end
endmodule

// Tri-state buffer module
module TriStateBuffer #(parameter BITS=8) (
    input oe,
    input [BITS-1:0] d,
    output [BITS-1:0] q
);
    assign q = oe ? d : {BITS{1'bz}};
endmodule

// Top-level module
module TriStateLatch #(parameter BITS=8) (
    input clk,
    input oe,
    input [BITS-1:0] d,
    output [BITS-1:0] q
);
    wire [BITS-1:0] latched_data;

    LatchCore #(.BITS(BITS)) latch_inst (
        .clk(clk),
        .d(d),
        .q(latched_data)
    );

    TriStateBuffer #(.BITS(BITS)) buffer_inst (
        .oe(oe),
        .d(latched_data),
        .q(q)
    );
endmodule