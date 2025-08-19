//SystemVerilog
// 顶层模块 - 流水线XNOR实现
module basic_xnor (
    input  wire        clk,     // 时钟输入
    input  wire        rst_n,   // 异步复位，低电平有效
    input  wire        in1,     // 第一个输入信号
    input  wire        in2,     // 第二个输入信号
    output wire        out,     // 最终XNOR结果
    output wire        valid    // 输出有效信号
);
    // 数据流水线寄存器
    reg stage1_valid, stage2_valid;
    reg stage1_xor_result;
    
    // 阶段1: XOR操作并寄存结果
    wire xor_result;
    xor_operation xor_inst (
        .a(in1),
        .b(in2),
        .result(xor_result)
    );
    
    // 阶段2: 取反操作
    inverter inv_inst (
        .in(stage1_xor_result),
        .out(out)
    );
    
    // 流水线控制 - 第一级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_xor_result <= 1'b0;
            stage1_valid <= 1'b0;
        end else begin
            stage1_xor_result <= xor_result;
            stage1_valid <= 1'b1;
        end
    end
    
    // 流水线控制 - 第二级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_valid <= 1'b0;
        end else begin
            stage2_valid <= stage1_valid;
        end
    end
    
    // 输出有效信号
    assign valid = stage2_valid;
    
endmodule

// XOR操作子模块 - 优化组合逻辑路径
module xor_operation (
    input  wire a,
    input  wire b,
    output wire result
);
    // 拆分XOR逻辑实现，降低逻辑深度
    wire a_and_not_b;
    wire not_a_and_b;
    
    // XOR的两部分计算
    assign a_and_not_b = a & ~b;
    assign not_a_and_b = ~a & b;
    
    // 合并两个部分的结果
    assign result = a_and_not_b | not_a_and_b;
    
endmodule

// 取反操作子模块 - 优化延迟
module inverter (
    input  wire in,
    output wire out
);
    // 直接实现取反，减少不必要的延迟
    assign out = ~in;
    
endmodule