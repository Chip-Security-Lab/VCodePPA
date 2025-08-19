//SystemVerilog
// Top-level module
module nand2_16 (
    input wire A, B,
    input wire clk,
    output reg Y
);
    // Direct combinational logic with registered output
    always @(posedge clk) begin
        Y <= ~(A & B);  // Directly implement NAND function in top module
    end
    
endmodule