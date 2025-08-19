//SystemVerilog
//IEEE 1364-2005 Verilog标准
///////////////////////////////////////////////////////////////////////////////
// File: logic_processor_top.v
// Description: Top-level module that coordinates the logic processing pipeline
///////////////////////////////////////////////////////////////////////////////
module logic_processor_top (
    input  wire clk,              // 系统时钟
    input  wire rst_n,            // 低电平有效复位信号
    input  wire [1:0] mode,       // 操作模式选择
    input  wire A, B, C,          // 基础输入信号
    output wire Y                 // 处理后的输出结果
);
    // 内部信号定义
    wire [1:0] processed_inputs;  // 预处理后的输入
    wire stage1_result;           // 第一阶段处理结果
    wire stage2_result;           // 第二阶段处理结果
    
    // 输入预处理模块
    input_preprocessor u_input_preprocessor (
        .clk          (clk),
        .rst_n        (rst_n),
        .mode         (mode),
        .raw_a        (A),
        .raw_b        (B),
        .raw_c        (C),
        .processed_ab (processed_inputs)
    );
    
    // 第一阶段逻辑处理器 - 处理XOR操作
    logic_stage1_processor u_logic_stage1 (
        .clk        (clk),
        .rst_n      (rst_n),
        .inputs     (processed_inputs),
        .in_a       (A),
        .in_b       (B),
        .xor_result (stage1_result)
    );
    
    // 第二阶段逻辑处理器 - 处理NAND操作
    logic_stage2_processor u_logic_stage2 (
        .clk         (clk),
        .rst_n       (rst_n),
        .in_a        (A),
        .in_c        (C),
        .nand_result (stage2_result)
    );
    
    // 输出合成器 - 组合最终结果
    output_synthesizer u_output_synthesizer (
        .clk        (clk),
        .rst_n      (rst_n),
        .mode       (mode),
        .stage1_out (stage1_result),
        .stage2_out (stage2_result),
        .final_out  (Y)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: input_preprocessor.v
// Description: Pre-processes input signals based on operational mode
///////////////////////////////////////////////////////////////////////////////
module input_preprocessor (
    input  wire       clk,           // 系统时钟
    input  wire       rst_n,         // 低电平有效复位信号
    input  wire [1:0] mode,          // 操作模式选择
    input  wire       raw_a,         // 原始输入A
    input  wire       raw_b,         // 原始输入B
    input  wire       raw_c,         // 原始输入C
    output reg  [1:0] processed_ab   // 处理后的AB信号
);
    // 基于模式进行输入预处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processed_ab <= 2'b00;
        end else begin
            case (mode)
                2'b00: processed_ab <= {raw_a, raw_b};      // 直接传递
                2'b01: processed_ab <= {raw_a, ~raw_b};     // B信号取反
                2'b10: processed_ab <= {~raw_a, raw_b};     // A信号取反
                2'b11: processed_ab <= {raw_b, raw_a};      // A/B信号交换
            endcase
        end
    end
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: logic_stage1_processor.v
// Description: First stage logic processing (XOR operation)
///////////////////////////////////////////////////////////////////////////////
module logic_stage1_processor (
    input  wire       clk,        // 系统时钟
    input  wire       rst_n,      // 低电平有效复位信号
    input  wire [1:0] inputs,     // 预处理后的输入
    input  wire       in_a,       // 直接输入A，用于可配置逻辑
    input  wire       in_b,       // 直接输入B，用于可配置逻辑
    output reg        xor_result  // XOR运算结果
);
    // 带时序控制的XOR运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_result <= 1'b0;
        end else begin
            // 增强型XOR操作，使用预处理后的输入
            xor_result <= inputs[1] ^ inputs[0];
            
            // 对于直接兼容性，保留原有XOR逻辑
            if (inputs == {in_a, in_b}) begin
                xor_result <= in_a ^ in_b;
            end
        end
    end
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: logic_stage2_processor.v
// Description: Second stage logic processing (NAND operation)
///////////////////////////////////////////////////////////////////////////////
module logic_stage2_processor (
    input  wire clk,         // 系统时钟
    input  wire rst_n,       // 低电平有效复位信号
    input  wire in_a,        // 输入A
    input  wire in_c,        // 输入C
    output reg  nand_result  // NAND运算结果
);
    // 带时序控制的NAND运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nand_result <= 1'b1;  // NAND的默认值为1
        end else begin
            nand_result <= ~(in_a & in_c);
        end
    end
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: output_synthesizer.v
// Description: Combines results from previous stages to produce final output
///////////////////////////////////////////////////////////////////////////////
module output_synthesizer (
    input  wire       clk,        // 系统时钟
    input  wire       rst_n,      // 低电平有效复位信号
    input  wire [1:0] mode,       // 操作模式选择
    input  wire       stage1_out, // 第一阶段输出 (XOR结果)
    input  wire       stage2_out, // 第二阶段输出 (NAND结果)
    output reg        final_out   // 最终输出结果
);
    // 组合最终输出，使用参数化设计
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_out <= 1'b0;
        end else begin
            case (mode)
                2'b00: final_out <= stage1_out & stage2_out;  // 原始AND操作
                2'b01: final_out <= stage1_out | stage2_out;  // 替代OR操作
                2'b10: final_out <= stage1_out ^ stage2_out;  // 替代XOR操作
                2'b11: final_out <= ~(stage1_out | stage2_out); // 替代NOR操作
            endcase
        end
    end
endmodule

///////////////////////////////////////////////////////////////////////////////
// File: compatibility_wrapper.v
// Description: Compatibility wrapper for legacy integration
///////////////////////////////////////////////////////////////////////////////
module xor_nand_gate (
    input  wire A, B, C,   // 输入A, B, C
    output wire Y          // 输出Y
);
    // 兼容性包装，实例化新的顶层模块
    logic_processor_top u_processor (
        .clk   (1'b0),     // 无时钟模式
        .rst_n (1'b1),     // 无复位状态
        .mode  (2'b00),    // 默认模式
        .A     (A),
        .B     (B),
        .C     (C),
        .Y     (Y)
    );
endmodule

// 为兼容性保留原始子模块定义
module xor_operation (
    input  wire in_a,
    input  wire in_b,
    output wire result
);
    assign result = in_a ^ in_b;
endmodule

module nand_operation (
    input  wire in_a,
    input  wire in_c,
    output wire result
);
    assign result = ~(in_a & in_c);
endmodule

module final_and_gate (
    input  wire in_xor,
    input  wire in_nand,
    output wire out_y
);
    assign out_y = in_xor & in_nand;
endmodule