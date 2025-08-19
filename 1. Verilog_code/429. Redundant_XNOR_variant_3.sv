//SystemVerilog IEEE 1364-2005
module Redundant_XNOR_System(
    input wire clk,        // 系统时钟
    input wire rst_n,      // 复位信号，低电平有效
    input wire in_valid,   // 输入有效信号
    input wire x, y,       // 输入操作数
    output reg out_valid,  // 输出有效信号
    output reg z           // 输出结果
);
    // 内部信号声明
    wire path1_result, path2_result;
    wire result_match, result_valid;
    
    // 实例化计算核心模块
    Computation_Core comp_core (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .x(x),
        .y(y),
        .path1_result(path1_result),
        .path2_result(path2_result)
    );
    
    // 实例化结果验证模块
    Result_Validator validator (
        .clk(clk),
        .rst_n(rst_n),
        .res1(path1_result),
        .res2(path2_result),
        .result_match(result_match),
        .result_valid(result_valid)
    );
    
    // 输出控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            z <= 1'b0;
        end else begin
            out_valid <= result_valid;
            z <= result_match ? path1_result : 1'b0; // 只有结果匹配时才输出
        end
    end
endmodule

//计算核心模块，包含两条冗余路径
module Computation_Core(
    input wire clk,
    input wire rst_n,
    input wire in_valid,
    input wire x, y,
    output reg path1_result,
    output reg path2_result
);
    // 内部信号
    wire xnor_res1, xnor_res2;
    
    // 实例化两个不同实现的XNOR路径
    XNOR_Implementation #(.IMPLEMENTATION_TYPE(1)) path1 (
        .in_a(x),
        .in_b(y),
        .out_res(xnor_res1)
    );
    
    XNOR_Implementation #(.IMPLEMENTATION_TYPE(2)) path2 (
        .in_a(x),
        .in_b(y),
        .out_res(xnor_res2)
    );
    
    // 注册计算结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            path1_result <= 1'b0;
            path2_result <= 1'b0;
        end else if (in_valid) begin
            path1_result <= xnor_res1;
            path2_result <= xnor_res2;
        end
    end
endmodule

// 参数化XNOR实现模块
module XNOR_Implementation #(
    parameter IMPLEMENTATION_TYPE = 1  // 1: ~(a^b), 2: a~^b
)(
    input wire in_a, in_b,
    output wire out_res
);
    // 根据参数选择不同实现
    generate
        if (IMPLEMENTATION_TYPE == 1) begin : USING_NOT_XOR
            // 使用非XOR实现XNOR
            assign out_res = ~(in_a ^ in_b);
        end else begin : USING_XNOR
            // 使用XNOR运算符直接实现
            assign out_res = in_a ~^ in_b;
        end
    endgenerate
endmodule

// 结果验证模块
module Result_Validator(
    input wire clk,
    input wire rst_n,
    input wire res1, res2,
    output reg result_match,  // 两路径结果是否匹配
    output reg result_valid   // 结果有效信号
);
    // 注册前结果比较
    wire paths_match = (res1 == res2);
    
    // 注册比较结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_match <= 1'b0;
            result_valid <= 1'b0;
        end else begin
            result_match <= paths_match;
            result_valid <= 1'b1;  // 可根据需要修改为延迟输出
        end
    end
endmodule