//SystemVerilog
// SystemVerilog
module enable_xnor (
    input  wire clk,    // 添加时钟信号用于流水线寄存器
    input  wire rst_n,  // 添加复位信号
    input  wire enable,
    input  wire a,
    input  wire b,
    output wire y       // 改为wire类型输出
);
    // 第一级：输入寄存器阶段
    reg enable_r1, a_r1, b_r1;
    
    // 第二级：计算阶段寄存器
    reg xnor_result;
    
    // 第三级：输出使能寄存器
    reg output_valid;
    reg xnor_gated;
    
    // 输入寄存器 - 数据流第一阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_r1 <= 1'b0;
            a_r1 <= 1'b0;
            b_r1 <= 1'b0;
        end else begin
            enable_r1 <= enable;
            a_r1 <= a;
            b_r1 <= b;
        end
    end
    
    // XNOR计算逻辑 - 数据流第二阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_result <= 1'b0;
            output_valid <= 1'b0;
        end else begin
            xnor_result <= ~(a_r1 ^ b_r1);
            output_valid <= enable_r1;
        end
    end
    
    // 输出使能控制 - 数据流第三阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_gated <= 1'b0;
        end else begin
            xnor_gated <= output_valid ? xnor_result : 1'b0;
        end
    end
    
    // 输出赋值
    assign y = xnor_gated;
    
endmodule