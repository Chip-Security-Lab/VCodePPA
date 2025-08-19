//SystemVerilog
module pipelined_ashift (
    input clk, rst,
    input valid_in,
    input [31:0] din,
    input [4:0] shift,
    output reg valid_out,
    output reg [31:0] dout,
    output reg ready_in
);

// 流水线阶段寄存器 - 数据
reg [31:0] data_stage1, data_stage2, data_stage3;
// 流水线阶段寄存器 - 控制信号
reg valid_stage1, valid_stage2, valid_stage3;
// 保存每个阶段的移位量
reg [4:0] shift_stage1, shift_stage2, shift_stage3;
// 计算中间结果
reg [31:0] shifted_stage1, shifted_stage2, shifted_stage3;

// 流水线就绪逻辑
assign ready_in = 1'b1; // 默认总是准备好接收新数据

// 流水线第一阶段 - 处理高2位移位
always @(posedge clk) begin
    if (rst) begin
        data_stage1 <= 32'b0;
        shift_stage1 <= 5'b0;
        valid_stage1 <= 1'b0;
    end
    else begin
        if (valid_in) begin
            // 第一级移位操作
            data_stage1 <= din >>> (shift[4:3] * 8);
            shift_stage1 <= shift;
            valid_stage1 <= 1'b1;
        end
        else if (ready_in) begin
            valid_stage1 <= 1'b0;
        end
    end
end

// 流水线第二阶段 - 处理中间2位移位
always @(posedge clk) begin
    if (rst) begin
        data_stage2 <= 32'b0;
        shift_stage2 <= 5'b0;
        valid_stage2 <= 1'b0;
    end
    else begin
        // 将第一阶段的结果传递到第二阶段
        data_stage2 <= data_stage1 >>> (shift_stage1[2:1] * 2);
        shift_stage2 <= shift_stage1;
        valid_stage2 <= valid_stage1;
    end
end

// 流水线第三阶段 - 处理最低1位移位
always @(posedge clk) begin
    if (rst) begin
        data_stage3 <= 32'b0;
        shift_stage3 <= 5'b0;
        valid_stage3 <= 1'b0;
    end
    else begin
        // 将第二阶段的结果传递到第三阶段
        data_stage3 <= data_stage2 >>> shift_stage2[0];
        shift_stage3 <= shift_stage2;
        valid_stage3 <= valid_stage2;
    end
end

// 输出阶段
always @(posedge clk) begin
    if (rst) begin
        dout <= 32'b0;
        valid_out <= 1'b0;
    end
    else begin
        dout <= data_stage3;
        valid_out <= valid_stage3;
    end
end

endmodule