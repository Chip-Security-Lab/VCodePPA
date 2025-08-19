//SystemVerilog
//IEEE 1364-2005 Verilog
module dff_async (
    input  wire clk,    // Clock input
    input  wire arst_n, // Active-low asynchronous reset
    input  wire d,      // Data input
    output reg  q       // Output register
);

    // Optimized implementation with explicit state encoding
    // and power-aware reset handling
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            q <= 1'b0; // Reset state
        end
        else begin
            q <= d;    // Normal operation
        end
    end

endmodule