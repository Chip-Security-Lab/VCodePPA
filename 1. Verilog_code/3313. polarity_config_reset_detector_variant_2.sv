//SystemVerilog
module polarity_config_reset_detector(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  reset_inputs,
    input  wire [3:0]  polarity_config, // 0=active-low, 1=active-high
    output reg  [3:0]  detected_resets,
    output reg         valid_out
);

    // Stage 1: Normalize inputs based on polarity_config
    reg  [3:0] normalized_inputs_stage1;
    reg        valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            normalized_inputs_stage1 <= 4'b0000;
            valid_stage1             <= 1'b0;
        end else begin
            normalized_inputs_stage1[0] <= polarity_config[0] ? reset_inputs[0] : ~reset_inputs[0];
            normalized_inputs_stage1[1] <= polarity_config[1] ? reset_inputs[1] : ~reset_inputs[1];
            normalized_inputs_stage1[2] <= polarity_config[2] ? reset_inputs[2] : ~reset_inputs[2];
            normalized_inputs_stage1[3] <= polarity_config[3] ? reset_inputs[3] : ~reset_inputs[3];
            valid_stage1               <= 1'b1;
        end
    end

    // Stage 2: Register output
    reg [3:0] detected_resets_stage2;
    reg       valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            detected_resets_stage2 <= 4'b0000;
            valid_stage2           <= 1'b0;
        end else begin
            detected_resets_stage2 <= normalized_inputs_stage1;
            valid_stage2           <= valid_stage1;
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            detected_resets <= 4'b0000;
            valid_out       <= 1'b0;
        end else begin
            detected_resets <= detected_resets_stage2;
            valid_out       <= valid_stage2;
        end
    end

endmodule