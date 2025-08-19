//SystemVerilog
//==========================================================
// 顶层模块 - 优化的XOR操作
//==========================================================
module xor2_19 (
    input  wire clk,     // 添加时钟输入用于流水线寄存器
    input  wire rst_n,   // 添加复位信号
    input  wire A, B,    // 输入信号
    output wire Y        // 输出信号
);
    // 数据流管道阶段定义
    wire stage1_result;  // 第一阶段结果
    reg  stage1_reg;     // 流水线寄存器
    reg  stage2_reg;     // 输出寄存器

    // 第一阶段 - 计算XOR结果
    xor_computation xor_comp_inst (
        .in_a      (A),
        .in_b      (B),
        .xor_result(stage1_result)
    );
    
    // 流水线寄存器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_reg <= 1'b0;
            stage2_reg <= 1'b0;
        end else begin
            // 流水线第一级寄存器
            stage1_reg <= stage1_result;
            // 流水线第二级寄存器
            stage2_reg <= stage1_reg;
        end
    end
    
    // 输出驱动
    output_driver out_drv_inst (
        .result_in(stage2_reg),
        .out_y    (Y)
    );
    
endmodule

//==========================================================
// 计算子模块 - 负责XOR逻辑运算（优化组合逻辑）
//==========================================================
module xor_computation (
    input  wire in_a, in_b,
    output wire xor_result
);
    // 优化为纯组合逻辑，提高效率
    assign xor_result = in_a ^ in_b;
endmodule

//==========================================================
// 输出驱动子模块 - 增强驱动能力
//==========================================================
module output_driver (
    input  wire result_in,
    output wire out_y
);
    // 添加更强的输出驱动
    assign out_y = result_in;
endmodule