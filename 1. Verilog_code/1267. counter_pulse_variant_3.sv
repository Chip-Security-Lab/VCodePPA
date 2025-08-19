//SystemVerilog
module counter_pulse #(parameter CYCLE=10) (
    input clk, rst,
    output reg pulse
);
    // 优化计数器位宽计算
    localparam CNT_WIDTH = $clog2(CYCLE);
    
    // 计数器及状态信号
    reg [CNT_WIDTH-1:0] cnt;
    reg counter_max;
    reg counter_max_pipe;
    
    // 预计算下一个计数值和比较结果
    wire [CNT_WIDTH-1:0] next_cnt;
    wire next_counter_max;
    
    // 计算下一个计数值 - 平衡关键路径
    assign next_cnt = (cnt == CYCLE-1) ? '0 : cnt + 1'b1;
    assign next_counter_max = (cnt == CYCLE-2); // 提前一个周期检测最大值
    
    // 计数器逻辑 - 优化后的计数与状态更新
    always @(posedge clk) begin
        if (rst) begin
            cnt <= '0;
            counter_max <= 1'b0;
            counter_max_pipe <= 1'b0;
            pulse <= 1'b0;
        end else begin
            cnt <= next_cnt;
            counter_max <= next_counter_max;
            counter_max_pipe <= counter_max;
            pulse <= counter_max_pipe;
        end
    end
endmodule