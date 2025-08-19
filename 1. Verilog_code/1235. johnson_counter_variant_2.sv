//SystemVerilog
module johnson_counter (
    input wire clk,
    input wire rst,
    input wire enable,  // 使能信号，控制流水线运行
    output reg [3:0] q,
    output reg valid_out  // 输出有效指示
);
    // 流水线阶段1：准备数据
    reg [3:0] q_stage1;
    reg valid_stage1;
    
    // 流水线阶段2：计算新值
    reg [3:0] q_stage2;
    reg valid_stage2;
    
    // 合并的流水线逻辑
    always @(posedge clk) begin
        if (rst) begin
            // 重置所有阶段寄存器
            q_stage1 <= 4'b0000;
            valid_stage1 <= 1'b0;
            q_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
            q <= 4'b0000;
            valid_out <= 1'b0;
        end
        else begin
            // 阶段1：数据准备
            if (enable) begin
                q_stage1 <= q;  // 获取当前计数值
                valid_stage1 <= 1'b1;
            end
            else begin
                valid_stage1 <= 1'b0;
            end
            
            // 阶段2：计算新值
            if (valid_stage1) begin
                q_stage2 <= {q_stage1[2:0], ~q_stage1[3]};  // 执行Johnson计数器的计算
                valid_stage2 <= valid_stage1;
            end
            else begin
                valid_stage2 <= 1'b0;
            end
            
            // 输出阶段：更新计数器值
            if (valid_stage2) begin
                q <= q_stage2;  // 更新输出
                valid_out <= valid_stage2;
            end
            else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule