//SystemVerilog
//IEEE 1364-2005
module int_ctrl_timeout #(
    parameter TIMEOUT = 8
) (
    input  wire clk,
    input  wire int_pending,
    output reg  timeout
);

    // 使用刚好足够的位宽来表示计数器
    localparam CNT_WIDTH = $clog2(TIMEOUT+1);
    reg [CNT_WIDTH-1:0] counter;
    wire at_timeout;
    wire [CNT_WIDTH-1:0] next_count;
    
    // 预计算下一个计数值
    assign next_count = counter + 1'b1;
    // 单独的超时检测逻辑
    assign at_timeout = (counter == TIMEOUT - 1'b1);
    
    always @(posedge clk) begin
        if (!int_pending) begin
            // 非中断挂起状态时重置计数器
            counter <= 'd0;
        end else if (at_timeout) begin
            // 达到超时阈值时重置
            counter <= 'd0;
        end else begin
            // 计数递增
            counter <= next_count;
        end
        
        // 超时信号逻辑
        timeout <= int_pending && at_timeout;
    end

endmodule