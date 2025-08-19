module dram_3d_stack #(
    parameter LAYERS = 4,
    parameter LAYER_BITS = 2
)(
    input clk,
    input [LAYER_BITS-1:0] layer_sel,
    output reg [LAYERS-1:0] layer_act,
    output reg [LAYERS-1:0] precharge_layers
);
    // Implementation for individual layer timing control
    always @(posedge clk) begin
        // Activate selected layer using one-hot encoding
        layer_act <= (1 << layer_sel);
        
        // Precharge all non-selected layers
        precharge_layers <= ~(1 << layer_sel) & {LAYERS{1'b1}};
    end
endmodule