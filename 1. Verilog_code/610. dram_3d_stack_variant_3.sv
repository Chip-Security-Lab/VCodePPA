//SystemVerilog
module dram_3d_stack #(
    parameter LAYERS = 4,
    parameter LAYER_BITS = 2
)(
    input clk,
    input rst_n,
    input [LAYER_BITS-1:0] layer_sel,
    output reg [LAYERS-1:0] layer_act,
    output reg [LAYERS-1:0] precharge_layers
);

    // Pipeline stage 1 registers
    reg [LAYER_BITS-1:0] layer_sel_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [LAYERS-1:0] layer_act_stage2;
    reg [LAYERS-1:0] precharge_layers_stage2;
    reg valid_stage2;

    // Stage 1: Input sampling and validation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            layer_sel_stage1 <= {LAYER_BITS{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            layer_sel_stage1 <= layer_sel;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Layer activation and precharge computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            layer_act_stage2 <= {LAYERS{1'b0}};
            precharge_layers_stage2 <= {LAYERS{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            case (layer_sel_stage1)
                {LAYER_BITS{1'b0}}: begin
                    layer_act_stage2 <= 4'b0001;
                    precharge_layers_stage2 <= 4'b1110;
                end
                {LAYER_BITS{1'b1}}: begin
                    layer_act_stage2 <= 4'b0010;
                    precharge_layers_stage2 <= 4'b1101;
                end
                default: begin
                    layer_act_stage2 <= 4'b0100;
                    precharge_layers_stage2 <= 4'b1011;
                end
            endcase
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            layer_act <= {LAYERS{1'b0}};
            precharge_layers <= {LAYERS{1'b0}};
        end else if (valid_stage2) begin
            layer_act <= layer_act_stage2;
            precharge_layers <= precharge_layers_stage2;
        end
    end

endmodule