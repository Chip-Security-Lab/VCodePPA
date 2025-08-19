//SystemVerilog
// Top module for a 4-bit NOT gate with negative edge triggering
// This module directly implements the 4-bit NOT gate without instantiating submodules.
module not_gate_4bit_neg_edge (
    input wire clk,
    input wire [3:0] A,
    output reg [3:0] Y
);
    // Register the inverted input on the negative edge of the clock.
    always @ (negedge clk) begin
        Y <= ~A;
    end
endmodule