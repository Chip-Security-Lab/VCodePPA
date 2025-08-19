//SystemVerilog
module ring_cascade_counter (
    input wire clk,
    input wire reset,
    output reg [3:0] stages,
    output reg carry_out
);

    // 定义流水线寄存器和控制信号
    reg [3:0] stages_stage1;
    reg valid_stage1;
    reg [3:0] stages_stage2;
    reg valid_stage2;
    
    // 阶段1: 更新环形计数器状态
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stages_stage1 <= 4'b1000;
            valid_stage1 <= 1'b0;
        end else begin
            stages_stage1 <= {stages[0], stages[3:1]};
            valid_stage1 <= 1'b1;
        end
    end
    
    // 阶段2: 检测特定条件和传递状态
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stages_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end else begin
            stages_stage2 <= stages_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段3: 生成输出
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stages <= 4'b1000;
            carry_out <= 1'b0;
        end else if (valid_stage2) begin
            stages <= stages_stage2;
            carry_out <= (stages_stage2[1:0] == 2'b01) && (stages_stage2[3:2] == 2'b00);
        end
    end

endmodule