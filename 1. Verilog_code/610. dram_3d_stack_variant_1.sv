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

    // Internal signals
    wire [LAYERS-1:0] one_hot_sel;
    wire [LAYERS-1:0] precharge_mask;
    reg [LAYERS-1:0] layer_act_next;
    reg [LAYERS-1:0] precharge_layers_next;

    // Combinational logic
    assign one_hot_sel = (1 << layer_sel);
    assign precharge_mask = ~one_hot_sel & {LAYERS{1'b1}};

    // Next state logic
    assign layer_act_next = one_hot_sel;
    assign precharge_layers_next = precharge_mask;

    // Sequential logic
    always @(posedge clk) begin
        layer_act <= layer_act_next;
        precharge_layers <= precharge_layers_next;
    end

endmodule