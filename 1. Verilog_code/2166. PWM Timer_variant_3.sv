//SystemVerilog
module pwm_timer (
    input clk, rst, enable,
    input [15:0] period, duty,
    output reg pwm_out
);
    reg [15:0] counter;
    
    // 合并counter和pwm_out的逻辑到同一个always块
    always @(posedge clk) begin
        case ({rst, enable})
            2'b10, 2'b11: begin  // rst=1，优先复位
                counter <= 16'd0;
                pwm_out <= 1'b0;
            end
            2'b01: begin         // enable=1, rst=0
                // 计数器逻辑
                counter <= (counter >= period - 1) ? 16'd0 : counter + 16'd1;
                // PWM输出逻辑
                pwm_out <= (counter < duty);
            end
            2'b00: begin         // enable=0, rst=0
                // 保持当前状态
                counter <= counter;
                pwm_out <= pwm_out;
            end
            default: begin       // 处理未定义状态
                counter <= counter;
                pwm_out <= pwm_out;
            end
        endcase
    end
endmodule