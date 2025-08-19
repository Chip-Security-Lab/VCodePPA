//SystemVerilog
module ring_cascade_counter (
    input wire clk,
    input wire reset,
    output reg [3:0] stages,
    output wire carry_out
);

    // 中间信号，用于流水线处理
    reg stage0_and_not_stage1;
    reg intermediate_result;
    reg carry_out_reg;
    
    // 第一级组合逻辑和流水线寄存器
    always @(posedge clk) begin
        if (reset)
            stage0_and_not_stage1 <= 1'b0;
        else
            stage0_and_not_stage1 <= stages[0] & ~stages[1];
    end
    
    // 第二级组合逻辑和流水线寄存器
    always @(posedge clk) begin
        if (reset)
            intermediate_result <= 1'b0;
        else
            intermediate_result <= stage0_and_not_stage1 & ~stages[2];
    end
    
    // 最终组合逻辑和流水线寄存器
    always @(posedge clk) begin
        if (reset)
            carry_out_reg <= 1'b0;
        else
            carry_out_reg <= intermediate_result & ~stages[3];
    end
    
    // 将流水线寄存器输出赋值给输出端口
    assign carry_out = carry_out_reg;
    
    // 移位寄存器逻辑保持不变
    always @(posedge clk) begin
        if (reset)
            stages <= 4'b1000;
        else
            stages <= {stages[0], stages[3:1]};
    end

endmodule