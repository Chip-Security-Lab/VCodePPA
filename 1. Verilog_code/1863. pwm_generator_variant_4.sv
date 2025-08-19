//SystemVerilog
module pwm_generator #(parameter CNT_W=8) (
    input clk, rst,
    input [CNT_W-1:0] duty_cycle,
    output reg pwm_out
);
    reg [CNT_W-1:0] cnt;
    wire [CNT_W:0] sum;
    wire [CNT_W-1:0] cnt_comp;
    
    // 计算cnt的补码
    assign cnt_comp = ~cnt + 1'b1;
    
    // 使用补码加法实现减法: duty_cycle + (-cnt)
    assign sum = duty_cycle + cnt_comp;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
            pwm_out <= 0;
        end else begin
            cnt <= cnt + 1;
            // 使用加法结果的最高位来判断大小关系
            pwm_out <= ~sum[CNT_W];
        end
    end
endmodule