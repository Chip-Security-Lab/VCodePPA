//SystemVerilog
module Timer_PrescaleDown #(parameter DIV=16) (
    input clk, rst_n, load_en,
    input [7:0] init_val,
    output reg timeup
);
    reg [7:0] counter;
    reg [7:0] counter_next;
    reg [$clog2(DIV)-1:0] ps_cnt;
    reg [$clog2(DIV)-1:0] ps_cnt_next;
    reg ps_cycle_complete;
    reg counter_zero;
    
    // 流水线寄存器，切割计数器计算逻辑
    always @(*) begin
        // 预分频计数器下一状态逻辑
        ps_cnt_next = ps_cycle_complete ? 0 : ps_cnt + 1'b1;
        
        // 计数器下一状态逻辑
        if (load_en)
            counter_next = init_val;
        else if (ps_cnt == 0 && !counter_zero)
            counter_next = counter - 1'b1;
        else
            counter_next = counter;
    end
    
    // 切割计数器比较逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ps_cycle_complete <= 1'b0;
            counter_zero <= 1'b0;
        end else begin
            ps_cycle_complete <= (ps_cnt == DIV-2); // 提前一个周期判断
            counter_zero <= (counter == 8'd1) || (counter == 8'd0 && !(ps_cnt == 0)); // 提前一个周期判断
        end
    end
    
    // 更新寄存器，实现时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ps_cnt <= 0;
            counter <= 0;
            timeup <= 1'b0;
        end else begin
            ps_cnt <= ps_cnt_next;
            counter <= counter_next;
            timeup <= (counter == 8'd0); // 将timeup信号与计数器状态直接关联
        end
    end
endmodule