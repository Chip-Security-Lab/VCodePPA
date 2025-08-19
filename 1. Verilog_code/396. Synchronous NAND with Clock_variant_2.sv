//SystemVerilog
module nand2_16 (
    input wire A, B,
    input wire clk,
    output reg Y
);
    // IEEE 1364-2005 Verilog standard compliant
    // Direct NAND implementation for improved efficiency
    always @(posedge clk) begin
        Y <= ~(A & B);
    end
endmodule