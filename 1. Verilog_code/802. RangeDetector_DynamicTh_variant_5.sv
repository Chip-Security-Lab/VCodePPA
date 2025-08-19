//SystemVerilog
module RangeDetector_DynamicTh #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,    // 添加复位信号
    input wr_en,
    input [WIDTH-1:0] new_low,
    input [WIDTH-1:0] new_high,
    input [WIDTH-1:0] data_in,
    input data_valid,    // 输入数据有效信号
    output reg out_flag,
    output reg out_valid  // 输出有效信号
);

// 流水线寄存器 - 阶段1
reg [WIDTH-1:0] current_low, current_high;
reg [WIDTH-1:0] data_stage1;
reg valid_stage1;

// 流水线寄存器 - 阶段2
reg low_comp_result_stage2;
reg high_comp_result_stage2;
reg valid_stage2;

// 阶段1: 寄存阈值更新和数据输入
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_low <= {WIDTH{1'b0}};
        current_high <= {WIDTH{1'b1}};
        data_stage1 <= {WIDTH{1'b0}};
        valid_stage1 <= 1'b0;
    end else begin
        // 更新阈值
        if (wr_en) begin
            current_low <= new_low;
            current_high <= new_high;
        end
        
        // 传递输入数据到第一级流水线
        data_stage1 <= data_in;
        valid_stage1 <= data_valid;
    end
end

// 阶段2: 阈值比较结果寄存
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        low_comp_result_stage2 <= 1'b0;
        high_comp_result_stage2 <= 1'b0;
        valid_stage2 <= 1'b0;
    end else begin
        // 计算比较结果并传递到第二级流水线
        low_comp_result_stage2 <= (data_stage1 >= current_low);
        high_comp_result_stage2 <= (data_stage1 <= current_high);
        valid_stage2 <= valid_stage1;
    end
end

// 阶段3: 最终结果计算
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_flag <= 1'b0;
        out_valid <= 1'b0;
    end else begin
        // 组合比较结果得到最终输出
        out_flag <= low_comp_result_stage2 && high_comp_result_stage2;
        out_valid <= valid_stage2;
    end
end

endmodule