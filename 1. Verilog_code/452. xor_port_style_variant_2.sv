//SystemVerilog
//=============================================================================
//=============================================================================
// 顶层模块 - 管理XOR门运算的整体结构
//=============================================================================
module xor_port_style #(
    parameter STAGE_REGISTERS = 1  // 参数化设计，允许配置流水线级数
)(
    input  wire clk,       // 时钟信号
    input  wire rst_n,     // 低有效复位
    input  wire a,         // 输入操作数A
    input  wire b,         // 输入操作数B
    output wire y          // 运算结果输出
);
    // 内部信号声明
    wire preprocessed_a, preprocessed_b;
    wire xor_result;
    
    // 输入预处理子模块实例化
    input_processor input_proc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .raw_a(a),
        .raw_b(b),
        .processed_a(preprocessed_a),
        .processed_b(preprocessed_b)
    );
    
    // 核心XOR逻辑运算子模块
    xor_computation #(
        .PIPELINE_STAGES(STAGE_REGISTERS)
    ) xor_comp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .operand_a(preprocessed_a),
        .operand_b(preprocessed_b),
        .result(xor_result)
    );
    
    // 输出后处理子模块
    output_processor output_proc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .xor_result(xor_result),
        .final_output(y)
    );
    
endmodule

//=============================================================================
// 输入预处理模块 - 处理输入信号
//=============================================================================
module input_processor (
    input  wire clk,
    input  wire rst_n,
    input  wire raw_a,
    input  wire raw_b,
    output reg  processed_a,
    output reg  processed_b
);
    // 可选的输入去抖动或同步
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processed_a <= 1'b0;
            processed_b <= 1'b0;
        end else begin
            processed_a <= raw_a;
            processed_b <= raw_b;
        end
    end
    
endmodule

//=============================================================================
// XOR计算核心模块 - 可配置流水线级数
//=============================================================================
module xor_computation #(
    parameter PIPELINE_STAGES = 1
)(
    input  wire clk,
    input  wire rst_n,
    input  wire operand_a,
    input  wire operand_b,
    output wire result
);
    // 处理逻辑
    generate
        if (PIPELINE_STAGES == 0) begin: NO_PIPELINE
            // 无流水线，纯组合逻辑
            assign result = operand_a ^ operand_b;
        end
        else begin: WITH_PIPELINE
            // 使用流水线寄存器
            reg [PIPELINE_STAGES:0] pipeline_regs;
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    pipeline_regs <= {(PIPELINE_STAGES+1){1'b0}};
                end else begin
                    pipeline_regs[0] <= operand_a ^ operand_b;
                    for (int i = 1; i <= PIPELINE_STAGES; i = i + 1) begin
                        pipeline_regs[i] <= pipeline_regs[i-1];
                    end
                end
            end
            
            assign result = pipeline_regs[PIPELINE_STAGES];
        end
    endgenerate
    
endmodule

//=============================================================================
// 输出处理模块 - 处理输出信号
//=============================================================================
module output_processor (
    input  wire clk,
    input  wire rst_n,
    input  wire xor_result,
    output reg  final_output
);
    // 输出缓冲或后处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_output <= 1'b0;
        end else begin
            final_output <= xor_result;
        end
    end
    
endmodule