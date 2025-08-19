//SystemVerilog
// 顶层模块
module SelfCheck_NAND #(
    parameter PERFORMANCE_LEVEL = 1,  // 参数化设计，可调整性能级别
    parameter PARITY_TYPE = 1,        // 0:偶校验, 1:奇校验
    parameter PIPELINE_STAGES = 2     // 流水线级数
)(
    input  wire clk,                  // 添加时钟输入用于流水线寄存器
    input  wire rst_n,                // 添加复位信号
    input  wire a,                    // 输入信号A
    input  wire b,                    // 输入信号B
    output wire y,                    // NAND结果输出
    output wire parity                // 奇偶校验输出
);

    // 数据流路径信号声明
    wire nand_result_comb;            // 组合逻辑NAND结果
    reg [PIPELINE_STAGES-1:0] nand_result_pipe; // 流水线寄存器链
    wire parity_gen_in;               // 连接到奇偶校验生成器的信号
    
    // 第一级：NAND逻辑计算
    NAND_Logic #(
        .PERFORMANCE_LEVEL(PERFORMANCE_LEVEL)
    ) nand_stage (
        .in_a(a),
        .in_b(b),
        .out_y(nand_result_comb)
    );
    
    // 第二级：流水线寄存器链，分割数据路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nand_result_pipe <= {PIPELINE_STAGES{1'b1}}; // NAND的默认状态为1
        end else begin
            // 流水线移位操作
            if (PIPELINE_STAGES > 1) begin
                nand_result_pipe[PIPELINE_STAGES-1:1] <= nand_result_pipe[PIPELINE_STAGES-2:0];
                nand_result_pipe[0] <= nand_result_comb;
            end else begin
                nand_result_pipe[0] <= nand_result_comb;
            end
        end
    end
    
    // 选择流水线输出作为奇偶校验的输入
    assign parity_gen_in = nand_result_pipe[PIPELINE_STAGES-1];
    
    // 第三级：奇偶校验生成
    Parity_Generator #(
        .PARITY_TYPE(PARITY_TYPE)
    ) parity_stage (
        .data_in(parity_gen_in),
        .parity_out(parity)
    );
    
    // 连接最终输出
    assign y = parity_gen_in; // 与流水线最后一级相同
    
endmodule

// 优化的NAND逻辑子模块
module NAND_Logic #(
    parameter PERFORMANCE_LEVEL = 1  // 参数化设计，可调整性能级别
)(
    input  wire in_a, 
    input  wire in_b,
    output wire out_y
);
    // 中间信号声明
    wire and_result;
    
    // 根据性能级别参数选择不同实现，影响PPA指标
    generate
        if (PERFORMANCE_LEVEL == 0) begin: LOW_POWER
            // 低功耗实现，最小面积
            assign out_y = ~(in_a & in_b);
        end 
        else if (PERFORMANCE_LEVEL == 1) begin: BALANCED
            // 标准实现，平衡性能和功耗
            // 增加中间寄存器以减少逻辑深度
            assign and_result = in_a & in_b;
            assign out_y = ~and_result;
        end 
        else begin: HIGH_PERFORMANCE
            // 高性能实现，优化时序路径
            // 使用德摩根定律减少逻辑深度，优化关键路径
            assign out_y = ~in_a | ~in_b;
        end
    endgenerate
endmodule

// 优化的奇偶校验生成子模块
module Parity_Generator #(
    parameter PARITY_TYPE = 1  // 0:偶校验, 1:奇校验
)(
    input  wire data_in,
    output wire parity_out
);
    // 奇偶校验逻辑保持简单，避免不必要的复杂性
    assign parity_out = (PARITY_TYPE == 1) ? data_in : ~data_in;
endmodule