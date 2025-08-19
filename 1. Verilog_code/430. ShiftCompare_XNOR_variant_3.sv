//SystemVerilog
module ShiftCompare_XNOR(
    input         clk,        // 添加时钟输入用于流水线
    input         rst_n,      // 添加复位信号
    input  [2:0]  shift,      // 移位控制输入
    input  [7:0]  base,       // 基础数据输入
    output [7:0]  res         // 结果输出
);
    // 数据流第一级：计算移位结果
    reg [7:0] shifted_data;
    reg [7:0] base_reg;
    
    // 数据流第二级：进行XNOR比较操作
    reg [7:0] result_reg;
    
    // 第一级流水线：计算移位数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_data <= 8'b0;
            base_reg <= 8'b0;
        end else begin
            shifted_data <= base << shift;
            base_reg <= base;
        end
    end
    
    // 第二级流水线：执行XNOR操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 8'b0;
        end else begin
            result_reg <= ~(shifted_data ^ base_reg);
        end
    end
    
    // 输出赋值
    assign res = result_reg;
    
endmodule