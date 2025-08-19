//SystemVerilog
// 顶层模块
module Hierarchical_AND (
    input  wire        clk,       // 时钟信号
    input  wire        rst_n,     // 复位信号，低电平有效
    input  wire [1:0]  in1, in2,  // 输入向量
    output wire [3:0]  res        // 结果输出
);
    // 内部信号声明 - 流水线阶段
    reg  [1:0] in1_reg, in2_reg;  // 输入寄存器
    wire [1:0] and_stage1;        // 第一阶段与运算结果
    reg  [1:0] and_result_reg;    // 寄存器级 - 存储与运算结果
    reg  [3:0] result_formatted;  // 最终格式化结果

    // 输入信号寄存 - 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in1_reg <= 2'b00;
            in2_reg <= 2'b00;
        end else begin
            in1_reg <= in1;
            in2_reg <= in2;
        end
    end

    // 实例化位操作子模块 - 组合逻辑阶段
    Bit_Operations bit_ops (
        .in1(in1_reg),
        .in2(in2_reg),
        .and_result(and_stage1)
    );
    
    // 中间结果寄存 - 第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result_reg <= 2'b00;
        end else begin
            and_result_reg <= and_stage1;
        end
    end
    
    // 结果格式化阶段 - 第三级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_formatted <= 4'b0000;
        end else begin
            result_formatted <= {2'b00, and_result_reg};
        end
    end
    
    // 输出赋值
    assign res = result_formatted;
endmodule

// 位操作子模块 - 处理按位与操作
module Bit_Operations (
    input  wire [1:0] in1, in2,
    output wire [1:0] and_result
);
    // 使用并行实现以减少逻辑深度
    AND_Primitive bit0(.a(in1[0]), .b(in2[0]), .y(and_result[0]));
    AND_Primitive bit1(.a(in1[1]), .b(in2[1]), .y(and_result[1]));
endmodule

// 基本与门原语 - 实现单比特与操作
module AND_Primitive (
    input  wire a, b,
    output wire y
);
    // 直接实现与门功能
    assign y = a & b;
endmodule