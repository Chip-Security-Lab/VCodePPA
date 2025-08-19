//SystemVerilog
module ConditionalNOT(
    input wire [31:0] data,
    input wire clk,
    input wire rst_n,
    output reg [31:0] result
);
    // 阶段1: 检测特殊条件和数据寄存
    reg is_all_ones;
    reg [31:0] data_r1;
    
    // 阶段2: 计算反转结果
    reg [31:0] inverted_data;
    reg is_all_ones_r1;
    
    // 第一级流水线: 优化检测条件并寄存数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_all_ones <= 1'b0;
            data_r1 <= 32'b0;
        end else begin
            // 优化比较：使用&运算符检查所有位是否为1，比全等比较更高效
            is_all_ones <= &data;
            data_r1 <= data;
        end
    end
    
    // 第二级流水线: 并行计算反转值和传递条件
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inverted_data <= 32'b0;
            is_all_ones_r1 <= 1'b0;
        end else begin
            // 优化：保持位反转逻辑，但确保并行性
            inverted_data <= ~data_r1;
            is_all_ones_r1 <= is_all_ones;
        end
    end
    
    // 第三级流水线: 使用位选择而非条件选择以优化输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 32'b0;
        end else begin
            // 使用位掩码技术提高效率
            result <= inverted_data & {32{~is_all_ones_r1}};
        end
    end
    
endmodule