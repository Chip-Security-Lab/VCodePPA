//SystemVerilog
module xor2_5 (
    input  wire clk,        // 添加时钟输入用于流水线寄存器
    input  wire rst_n,      // 添加复位信号
    input  wire A, B, C, D, // 数据输入
    output wire Y           // 最终结果输出
);
    // 流水线阶段信号定义
    wire stage1_result;     // 第一阶段XOR结果
    reg  stage1_reg;        // 第一阶段流水线寄存器
    wire stage2_result;     // 第二阶段XOR结果 (CD组合)
    reg  stage2_reg;        // 第二阶段流水线寄存器
    
    // 数据流第一阶段 - A⊕B组合
    xor2_datapath u_stage1_datapath (
        .data_a(A),
        .data_b(B),
        .result(stage1_result)
    );
    
    // 数据流第二阶段 - C⊕D组合
    xor2_datapath u_stage2_datapath (
        .data_a(C),
        .data_b(D),
        .result(stage2_result)
    );
    
    // 流水线寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_reg <= 1'b0;
            stage2_reg <= 1'b0;
        end else begin
            stage1_reg <= stage1_result;
            stage2_reg <= stage2_result;
        end
    end
    
    // 最终数据流合并阶段
    xor2_datapath u_final_datapath (
        .data_a(stage1_reg),
        .data_b(stage2_reg),
        .result(Y)
    );
endmodule

// 优化的2输入XOR数据通路模块
module xor2_datapath (
    input  wire data_a,
    input  wire data_b,
    output wire result
);
    // 使用优化的XOR实现
    assign result = data_a ^ data_b;
endmodule