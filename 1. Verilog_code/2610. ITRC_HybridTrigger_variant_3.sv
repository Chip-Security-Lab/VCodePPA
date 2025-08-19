//SystemVerilog
module ITRC_HybridTrigger #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] level_int,
    input [WIDTH-1:0] edge_int,
    output [WIDTH-1:0] triggered
);
    reg [WIDTH-1:0] edge_reg;
    reg [WIDTH-1:0] trigger_lut [0:3];
    
    // Initialize LUT
    initial begin
        trigger_lut[0] = 0;  // ~edge_int & ~edge_reg
        trigger_lut[1] = 1;  // ~edge_int & edge_reg
        trigger_lut[2] = 1;  // edge_int & ~edge_reg
        trigger_lut[3] = 1;  // edge_int & edge_reg
    end
    
    // Edge detection
    always @(posedge clk) begin
        if (!rst_n) edge_reg <= 0;
        else edge_reg <= edge_int;
    end
    
    // Trigger generation using LUT
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : trigger_gen
            wire [1:0] lut_index = {edge_int[i], edge_reg[i]};
            assign triggered[i] = trigger_lut[lut_index] & (level_int[i] | edge_int[i]);
        end
    endgenerate
endmodule