//SystemVerilog
module or_gate_4input_1bit (
    input wire a,
    input wire b,
    input wire c,
    input wire d,
    output wire y
);
    // 参数定义
    parameter STAGE1_DELAY = 0;
    parameter STAGE2_DELAY = 0;
    
    // 内部连接信号
    wire [1:0] intermediate_results;
    
    // 实例化二级树形OR结构
    or_stage #(
        .WIDTH(2),
        .DELAY(STAGE1_DELAY)
    ) first_stage (
        .inputs({a, b, c, d}),
        .outputs(intermediate_results)
    );
    
    or_gate_generic #(
        .WIDTH(2),
        .DELAY(STAGE2_DELAY)
    ) final_stage (
        .inputs(intermediate_results),
        .result(y)
    );
endmodule

// 通用的OR门模块，支持任意位宽输入
module or_gate_generic #(
    parameter WIDTH = 2,
    parameter DELAY = 0
)(
    input wire [WIDTH-1:0] inputs,
    output wire result
);
    // 可配置延迟的归约OR操作
    assign #(DELAY) result = |inputs;
endmodule

// 树形OR结构的一个阶段
module or_stage #(
    parameter WIDTH = 4,     // 输入总位宽
    parameter DELAY = 0,     // 每个OR门的延迟
    parameter PAIRS = WIDTH/2 // 输出对数量
)(
    input wire [WIDTH-1:0] inputs,
    output wire [PAIRS-1:0] outputs
);
    genvar i;
    generate
        for (i = 0; i < PAIRS; i = i + 1) begin : pair_or
            assign #(DELAY) outputs[i] = inputs[i*2] | inputs[i*2+1];
        end
    endgenerate
endmodule