//SystemVerilog
module dram_3d_stack #(
    parameter LAYERS = 4,
    parameter LAYER_BITS = 2
)(
    input clk,
    input [LAYER_BITS-1:0] layer_sel,
    output reg [LAYERS-1:0] layer_act,
    output reg [LAYERS-1:0] precharge_layers
);

    // Optimized one-hot decoder implementation
    wire [LAYERS-1:0] one_hot;
    wire [LAYERS-1:0] one_hot_inv;
    
    // Direct one-hot encoding without generate block
    assign one_hot = (1'b1 << layer_sel);
    assign one_hot_inv = ~one_hot;

    // Register outputs with optimized timing
    always @(posedge clk) begin
        layer_act <= one_hot;
        precharge_layers <= one_hot_inv;
    end

endmodule