//SystemVerilog
module ring_cascade_counter (
    input wire clk,
    input wire reset,
    output reg [3:0] stages,
    output wire carry_out
);
    // 中间流水线寄存器
    reg [3:0] stages_stage1;
    reg carry_out_stage1;
    reg [3:0] stages_stage2;
    
    // 计算下一个状态
    wire [3:0] next_stages = {stages[0], stages[3:1]};
    
    // 多级流水线逻辑
    always @(posedge clk) begin
        if (reset) begin
            // 第一级流水线
            stages_stage1 <= 4'b1000;
            carry_out_stage1 <= 1'b0;
            
            // 第二级流水线
            stages_stage2 <= 4'b1000;
            
            // 输出级
            stages <= 4'b1000;
        end
        else begin
            // 第一级流水线 - 计算状态和进位
            stages_stage1 <= next_stages;
            carry_out_stage1 <= (stages == 4'b0001);
            
            // 第二级流水线 - 传递状态
            stages_stage2 <= stages_stage1;
            
            // 输出级 - 最终状态
            stages <= stages_stage2;
        end
    end
    
    // 输出进位
    assign carry_out = carry_out_stage1;
    
endmodule