//SystemVerilog
module ring_oscillator(
    input wire clk,        // 时钟输入
    input wire rst_n,      // 复位信号
    input wire enable,     // 使能信号
    output wire clk_out    // 时钟输出
);
    // 流水线阶段寄存器
    reg [4:0] stage1_reg;
    reg [4:0] stage2_reg;
    reg [4:0] stage3_reg;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 阶段1: 初始反转
    wire [4:0] stage1_next;
    assign stage1_next[0] = enable ? ~stage3_reg[4] : 1'b0;
    assign stage1_next[1] = ~stage3_reg[0];
    assign stage1_next[2] = ~stage3_reg[1];
    assign stage1_next[3] = ~stage3_reg[2];
    assign stage1_next[4] = ~stage3_reg[3];
    
    // 阶段2和3仅传递数据 (流水线深度增加)
    
    // 流水线寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            // 复位所有流水线寄存器
            stage1_reg <= 5'b0;
            stage2_reg <= 5'b0;
            stage3_reg <= 5'b0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            // 正常流水线操作
            stage1_reg <= stage1_next;
            stage2_reg <= stage1_reg;
            stage3_reg <= stage2_reg;
            
            // 流水线控制信号传递
            valid_stage1 <= enable;
            valid_stage2 <= valid_stage1;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出信号路径
    assign clk_out = valid_stage3 ? stage3_reg[4] : 1'b0;
    
endmodule