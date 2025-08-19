//SystemVerilog
//IEEE 1364-2005 Verilog标准
`timescale 1ns / 1ps

module and_not_gate (
    input  wire A, B,   // 输入信号
    input  wire clk,    // 添加时钟信号到顶层接口
    output wire Y       // 输出结果
);
    // 定义内部数据流信号
    wire stage1_and_comb;     // 组合逻辑AND结果
    reg  stage1_and_result;   // 寄存的AND结果
    reg  a_delayed;           // 寄存的A输入
    
    // 第一级：组合逻辑计算AND结果
    stage1_combinational stage1_comb (
        .a_in(A),
        .b_in(B),
        .and_result(stage1_and_comb)
    );
    
    // 第一级：时序逻辑寄存中间结果
    stage1_sequential stage1_seq (
        .clk(clk),
        .a_in(A),
        .and_comb(stage1_and_comb),
        .and_result(stage1_and_result),
        .a_delayed(a_delayed)
    );
    
    // 第二级：最终组合逻辑计算
    stage2_combinational stage2 (
        .and_result(stage1_and_result),
        .a_delayed(a_delayed),
        .final_output(Y)
    );
endmodule

// 第一级组合逻辑处理：AND计算
module stage1_combinational (
    input  wire a_in, b_in,
    output wire and_result
);
    // 纯组合逻辑实现AND运算
    assign and_result = a_in & b_in;
endmodule

// 第一级时序逻辑处理：寄存中间结果
module stage1_sequential (
    input  wire clk,
    input  wire a_in,
    input  wire and_comb,
    output reg  and_result,
    output reg  a_delayed
);
    // 时序逻辑：寄存中间结果，使用时钟触发
    always @(posedge clk) begin
        and_result <= and_comb;  // 寄存AND结果
        a_delayed  <= a_in;      // 寄存输入A以匹配流水线延迟
    end
endmodule

// 第二级组合逻辑处理：最终逻辑计算
module stage2_combinational (
    input  wire and_result, a_delayed,
    output wire final_output
);
    // 纯组合逻辑实现最终运算
    // (A & B) & ~A 在数学上等价于 0，但保留实际实现以便功能验证
    assign final_output = and_result & ~a_delayed;
endmodule