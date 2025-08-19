//SystemVerilog
module mux_dff (
    input logic clk,
    input logic rst_n, // 添加复位信号
    input logic sel,
    input logic d0, d1,
    input logic valid_in, // 输入有效信号
    output logic q,
    output logic valid_out // 输出有效信号
);

    // 流水线第一级 - 输入寄存
    logic sel_stage1, d0_stage1, d1_stage1;
    logic valid_stage1;

    // 流水线第二级 - 选择结果寄存
    logic q_stage2;
    logic valid_stage2;

    // 第一级流水线 - 寄存输入信号
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_stage1 <= 1'b0;
            d0_stage1 <= 1'b0;
            d1_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            sel_stage1 <= sel;
            d0_stage1 <= d0;
            d1_stage1 <= d1;
            valid_stage1 <= valid_in;
        end
    end

    // 第二级流水线 - 执行选择操作并寄存结果
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                q_stage2 <= sel_stage1 ? d1_stage1 : d0_stage1;
            end
            valid_stage2 <= valid_stage1;
        end
    end

    // 输出赋值
    assign q = q_stage2;
    assign valid_out = valid_stage2;

endmodule