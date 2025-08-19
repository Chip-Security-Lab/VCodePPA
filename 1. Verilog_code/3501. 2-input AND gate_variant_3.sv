//SystemVerilog
//IEEE 1364-2005 Verilog
`timescale 1ns/1ps

/**
 * 参数化2输入与门模块 - 优化数据流结构
 * 支持可配置的传播延迟
 * 实现流水线结构以改善PPA指标
 */
module and_gate_2 #(
    parameter DELAY = 0,           // 可配置的传播延迟（单位：ns）
    parameter PIPELINE_STAGES = 0  // 可配置的流水线级数
) (
    input  wire        clk,        // 时钟信号
    input  wire        rst_n,      // 低电平有效复位信号
    input  wire        a,          // 输入信号 A
    input  wire        b,          // 输入信号 B
    output wire        y           // 输出信号 Y = A & B
);

    // 内部信号声明
    wire and_result;
    reg [PIPELINE_STAGES:0] pipeline_regs;
    
    // 组合逻辑部分 - 基本与运算
    assign and_result = a & b;
    
    // 流水线结构实现
    generate
        if (PIPELINE_STAGES == 0) begin : NO_PIPELINE
            // 直接输出，带延迟
            assign #(DELAY) y = and_result;
        end
        else begin : WITH_PIPELINE
            // 流水线寄存器链
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    // 异步复位
                    pipeline_regs <= {(PIPELINE_STAGES+1){1'b0}};
                end
                else begin
                    // 流水线移位
                    pipeline_regs[0] <= and_result;
                    for (int i = 1; i <= PIPELINE_STAGES; i = i + 1) begin
                        pipeline_regs[i] <= pipeline_regs[i-1];
                    end
                end
            end
            
            // 最终输出带延迟
            assign #(DELAY) y = pipeline_regs[PIPELINE_STAGES];
        end
    endgenerate

endmodule