//SystemVerilog
module fractional_divider #(
    parameter ACC_WIDTH = 8,
    parameter STEP = 85  // 1.6分频示例值（STEP = 256 * 5/8）
)(
    input clk,
    input rst,
    output reg clk_out
);

// Pipeline registers
reg [ACC_WIDTH-1:0] phase_acc_stage1;
reg [ACC_WIDTH-1:0] phase_acc_stage2;
reg valid_stage1, valid_stage2;
reg clk_out_stage1;

// Stage 1: Accumulation
always @(posedge clk or posedge rst) begin
    if (rst) begin
        phase_acc_stage1 <= 0;
        valid_stage1 <= 0;
    end else begin
        phase_acc_stage1 <= phase_acc_stage1 + STEP;
        valid_stage1 <= 1'b1;
    end
end

// Stage 2: Clock generation
always @(posedge clk or posedge rst) begin
    if (rst) begin
        phase_acc_stage2 <= 0;
        clk_out_stage1 <= 0;
        valid_stage2 <= 0;
    end else begin
        phase_acc_stage2 <= phase_acc_stage1;
        clk_out_stage1 <= phase_acc_stage1[ACC_WIDTH-1];
        valid_stage2 <= valid_stage1;
    end
end

// Output stage
always @(posedge clk or posedge rst) begin
    if (rst) begin
        clk_out <= 0;
    end else if (valid_stage2) begin
        clk_out <= clk_out_stage1;
    end
end

endmodule