//SystemVerilog
// 顶层模块 - 优化的NAND和XOR组合操作
module nand_xor_gate #(
    parameter OPTIMIZE_AREA = 1,
    parameter PIPELINE_STAGES = 2  // 新增流水线级数参数
)(
    input  wire clk,              // 新增时钟信号用于流水线寄存器
    input  wire rst_n,            // 新增复位信号用于寄存器初始化
    input  wire A, B, C,          // 输入信号
    output wire Y                  // 输出结果
);
    // 内部数据流信号
    wire nand_result;
    wire xor_result;
    
    // 流水线寄存器
    reg [PIPELINE_STAGES-1:0] pipeline_nand;
    reg [PIPELINE_STAGES-1:0] pipeline_c;
    
    // 第一级：NAND操作
    optimized_nand_unit nand_stage (
        .in_a(A),
        .in_b(B),
        .nand_out(nand_result)
    );
    
    // 流水线寄存器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_nand <= {PIPELINE_STAGES{1'b0}};
            pipeline_c <= {PIPELINE_STAGES{1'b0}};
        end else begin
            // 将结果和C输入移入流水线寄存器
            pipeline_nand <= {pipeline_nand[PIPELINE_STAGES-2:0], nand_result};
            pipeline_c <= {pipeline_c[PIPELINE_STAGES-2:0], C};
        end
    end
    
    // 第二级：XOR操作
    optimized_xor_unit #(
        .OPTIMIZE_AREA(OPTIMIZE_AREA)
    ) xor_stage (
        .in_a(pipeline_nand[PIPELINE_STAGES-1]),
        .in_b(pipeline_c[PIPELINE_STAGES-1]),
        .xor_out(Y)
    );
endmodule

// 优化的NAND运算单元
module optimized_nand_unit (
    input  wire in_a, in_b,
    output wire nand_out
);
    // 执行NAND操作，优化信号命名
    assign nand_out = ~(in_a & in_b);
endmodule

// 优化的XOR运算单元
module optimized_xor_unit #(
    parameter OPTIMIZE_AREA = 1
)(
    input  wire in_a, in_b,
    output wire xor_out
);
    generate
        if (OPTIMIZE_AREA) begin : area_optimized_path
            // 使用分解的XOR实现，面积优化
            wire and_path1, and_path2;
            wire not_a, not_b;
            
            // 信号反转阶段
            assign not_a = ~in_a;
            assign not_b = ~in_b;
            
            // 并行AND路径
            assign and_path1 = in_a & not_b;
            assign and_path2 = not_a & in_b;
            
            // 最终OR合并
            assign xor_out = and_path1 | and_path2;
        end else begin : speed_optimized_path
            // 高速直接XOR路径实现
            assign xor_out = in_a ^ in_b;
        end
    endgenerate
endmodule