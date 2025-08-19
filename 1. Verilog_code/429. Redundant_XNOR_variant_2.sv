//SystemVerilog
// 顶层模块
module Redundant_XNOR_System(
    input wire clk,         // 添加时钟信号以支持流水线
    input wire rst_n,       // 添加复位信号
    input wire x, y,        // 输入信号
    output wire z,          // 输出结果
    output wire error_flag  // 添加错误标志输出
);
    // 内部连线
    wire t1, t2;
    wire valid_signal;
    
    // 实例化XNOR计算单元
    XNOR_Computation_Unit compute_unit (
        .clk(clk),
        .rst_n(rst_n),
        .in1(x),
        .in2(y),
        .result1(t1),
        .result2(t2)
    );
    
    // 实例化结果验证和错误检测单元
    Result_Validation_Unit validate_unit (
        .clk(clk),
        .rst_n(rst_n),
        .result1(t1),
        .result2(t2),
        .valid_result(z),
        .error_detected(error_flag)
    );
endmodule

// XNOR计算单元，整合两种不同实现的计算路径
module XNOR_Computation_Unit(
    input wire clk,
    input wire rst_n,
    input wire in1, in2,
    output reg result1, result2
);
    // 内部连线
    wire path1_result, path2_result;
    
    // 实现路径1：使用基本逻辑门
    XNOR_Implementation_Type1 path1 (
        .in1(in1),
        .in2(in2),
        .out(path1_result)
    );
    
    // 实现路径2：使用XNOR操作符
    XNOR_Implementation_Type2 path2 (
        .in1(in1),
        .in2(in2),
        .out(path2_result)
    );
    
    // 注册输出，提高时序性能
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result1 <= 1'b0;
            result2 <= 1'b0;
        end else begin
            result1 <= path1_result;
            result2 <= path2_result;
        end
    end
endmodule

// 结果验证和错误检测单元
module Result_Validation_Unit(
    input wire clk,
    input wire rst_n,
    input wire result1, result2,
    output reg valid_result,
    output reg error_detected
);
    wire results_match;
    
    // 判断两个结果是否一致
    assign results_match = (result1 == result2);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_result <= 1'b0;
            error_detected <= 1'b0;
        end else begin
            valid_result <= result1 & results_match;  // 仅当结果匹配时输出result1
            error_detected <= ~results_match;         // 结果不匹配时置位错误标志
        end
    end
endmodule

// 子模块1: 使用基本逻辑门实现XNOR
module XNOR_Implementation_Type1(
    input wire in1, in2,
    output wire out
);
    wire xor_result;
    
    // 使用XOR然后取反实现XNOR
    assign xor_result = in1 ^ in2;
    assign out = ~xor_result;
endmodule

// 子模块2: 使用XNOR操作符实现XNOR
module XNOR_Implementation_Type2(
    input wire in1, in2,
    output wire out
);
    // 直接使用XNOR操作符
    assign out = in1 ~^ in2;
endmodule