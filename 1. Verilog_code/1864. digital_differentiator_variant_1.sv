//SystemVerilog
module digital_differentiator #(parameter WIDTH=8) (
    input clk, rst,
    input [WIDTH-1:0] data_in,
    input valid_in,           // 输入数据有效信号
    output valid_out,         // 输出数据有效信号
    output [WIDTH-1:0] data_diff
);

// 流水线第一级寄存器
reg [WIDTH-1:0] stage1_data;
reg stage1_valid;

// 流水线第二级寄存器
reg [WIDTH-1:0] stage2_data_in;
reg [WIDTH-1:0] stage2_prev_data;
reg stage2_valid;

// 流水线第三级寄存器（输出级）
reg [WIDTH-1:0] stage3_diff;
reg stage3_valid;

// 第一级流水线 - 寄存输入数据
always @(posedge clk or posedge rst) begin
    if (rst) begin
        stage1_data <= 0;
        stage1_valid <= 0;
    end
    else begin
        stage1_data <= data_in;
        stage1_valid <= valid_in;
    end
end

// 第二级流水线 - 保存当前数据和前一个数据
always @(posedge clk or posedge rst) begin
    if (rst) begin
        stage2_data_in <= 0;
        stage2_prev_data <= 0;
        stage2_valid <= 0;
    end
    else begin
        stage2_data_in <= stage1_data;
        stage2_prev_data <= stage2_data_in;
        stage2_valid <= stage1_valid;
    end
end

// 第三级流水线 - 计算差分并输出
always @(posedge clk or posedge rst) begin
    if (rst) begin
        stage3_diff <= 0;
        stage3_valid <= 0;
    end
    else begin
        stage3_diff <= stage2_data_in ^ stage2_prev_data;
        stage3_valid <= stage2_valid;
    end
end

// 输出赋值
assign data_diff = stage3_diff;
assign valid_out = stage3_valid;

endmodule