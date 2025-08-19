//SystemVerilog
module Sync_NAND(
    input clk,
    input [7:0] d1, d2,
    output [7:0] q
);
    // Registers moved to inputs
    reg [7:0] d1_reg, d2_reg;
    
    // Register the inputs
    always @(posedge clk) begin
        d1_reg <= d1;
        d2_reg <= d2;
    end
    
    // Combinational output using registered inputs
    assign q = ~(d1_reg & d2_reg);
endmodule