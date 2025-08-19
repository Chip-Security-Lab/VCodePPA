//SystemVerilog
module pwm_generator #(parameter CNT_W=8) (
    input clk, rst, 
    input [CNT_W-1:0] duty_cycle,
    output reg pwm_out
);
    reg [CNT_W-1:0] cnt;
    reg [CNT_W-1:0] duty_cycle_reg;
    wire pwm_comb;
    
    // 将duty_cycle输入进行寄存，推迟到组合逻辑之后
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            duty_cycle_reg <= 0;
            cnt <= 0;
        end else begin
            duty_cycle_reg <= duty_cycle;
            cnt <= cnt + 1;
        end
    end
    
    // 将比较逻辑从时序逻辑中分离出来
    assign pwm_comb = (cnt < duty_cycle_reg);
    
    // 将输出寄存器移动到组合逻辑之后
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pwm_out <= 0;
        end else begin
            pwm_out <= pwm_comb;
        end
    end
endmodule