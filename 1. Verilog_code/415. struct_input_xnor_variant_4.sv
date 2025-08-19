//SystemVerilog
module struct_input_xnor (
    input wire clock,      // 添加时钟输入用于流水线寄存器
    input wire reset_n,    // 添加复位信号
    input wire [3:0] a_in, 
    input wire [3:0] b_in,
    output reg [3:0] struct_out
);
    // 内部流水线寄存器
    reg [3:0] a_stage1, b_stage1;
    reg [3:0] and_result_stage2;
    reg [3:0] nand_result_stage2;
    
    // 阶段1: 输入注册和补码生成
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            a_stage1 <= 4'b0000;
            b_stage1 <= 4'b0000;
        end else begin
            a_stage1 <= a_in;
            b_stage1 <= b_in;
        end
    end
    
    // 阶段2: 并行计算AND和NAND项
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            and_result_stage2 <= 4'b0000;
            nand_result_stage2 <= 4'b0000;
        end else begin
            and_result_stage2 <= a_stage1 & b_stage1;
            nand_result_stage2 <= (~a_stage1) & (~b_stage1);
        end
    end
    
    // 阶段3: 最终OR操作和输出寄存
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            struct_out <= 4'b0000;
        end else begin
            struct_out <= and_result_stage2 | nand_result_stage2;
        end
    end
    
endmodule