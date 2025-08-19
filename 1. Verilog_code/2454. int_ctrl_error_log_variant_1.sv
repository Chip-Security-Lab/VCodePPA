//SystemVerilog
module int_ctrl_error_log #(parameter ERR_BITS=4)(
    input wire clk,
    input wire rst,
    input wire [ERR_BITS-1:0] err_in,
    output reg [ERR_BITS-1:0] err_log,
    // 流水线控制信号
    input wire valid_in,
    output reg valid_out
);

    // 定义流水线阶段寄存器
    reg [ERR_BITS-1:0] err_stage1;
    reg [ERR_BITS-1:0] err_stage2;
    reg valid_stage1, valid_stage2;

    // 第一级流水线：捕获输入错误
    always @(posedge clk) begin
        if (rst) begin
            err_stage1 <= {ERR_BITS{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else begin
            err_stage1 <= err_in;
            valid_stage1 <= valid_in;
        end
    end

    // 第二级流水线：处理累积逻辑
    always @(posedge clk) begin
        if (rst) begin
            err_stage2 <= {ERR_BITS{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            err_stage2 <= valid_stage1 ? (err_stage1 | err_log) : err_log;
            valid_stage2 <= valid_stage1;
        end
    end

    // 输出级：更新错误日志
    always @(posedge clk) begin
        if (rst) begin
            err_log <= {ERR_BITS{1'b0}};
            valid_out <= 1'b0;
        end
        else begin
            if (valid_stage2) begin
                err_log <= err_stage2;
            end
            valid_out <= valid_stage2;
        end
    end

endmodule