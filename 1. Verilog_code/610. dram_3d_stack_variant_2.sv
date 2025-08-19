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

    // Barrel shifter implementation for layer activation
    always @(posedge clk) begin
        case(layer_sel)
            2'd0: layer_act <= 4'b0001;
            2'd1: layer_act <= 4'b0010;
            2'd2: layer_act <= 4'b0100;
            2'd3: layer_act <= 4'b1000;
            default: layer_act <= 4'b0000;
        endcase
    end

    // Barrel shifter implementation for precharge layers
    always @(posedge clk) begin
        case(layer_sel)
            2'd0: precharge_layers <= 4'b1110;
            2'd1: precharge_layers <= 4'b1101;
            2'd2: precharge_layers <= 4'b1011;
            2'd3: precharge_layers <= 4'b0111;
            default: precharge_layers <= 4'b1111;
        endcase
    end

endmodule