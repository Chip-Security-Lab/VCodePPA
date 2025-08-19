//SystemVerilog
// 顶层模块 - 4输入异或门
module xor2_17 (
    input  wire A, B, C, D,
    output wire Y
);
    // 内部连线
    wire xor_stage1_out;
    
    // 子模块实例化
    xor2_input_stage u_input_stage (
        .inputs({A, B, C, D}),
        .result(xor_stage1_out)
    );
    
    xor2_output_stage u_output_stage (
        .in(xor_stage1_out),
        .out(Y)
    );
endmodule

// 输入处理子模块 - 处理4个输入信号
module xor2_input_stage #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] inputs,
    output wire result
);
    // 内部信号
    wire [WIDTH/2-1:0] intermediate_results;
    
    // 第一级异或运算
    genvar i;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : xor_pairs
            assign intermediate_results[i] = inputs[i*2] ^ inputs[i*2+1];
        end
    endgenerate
    
    // 合并第一级结果
    assign result = ^intermediate_results;
endmodule

// 输出处理子模块 - 缓冲输出以提高驱动能力
module xor2_output_stage (
    input  wire in,
    output wire out
);
    // 简单的非反相缓冲器实现
    // 在实际应用中可以根据需要调整缓冲级数和驱动强度
    assign out = in;
endmodule