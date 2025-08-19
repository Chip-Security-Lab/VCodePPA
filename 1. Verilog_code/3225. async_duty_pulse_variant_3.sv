//SystemVerilog
module async_duty_pulse(
    input clk,
    input arst,
    input [7:0] period,
    input [2:0] duty_sel,  // 0-7 representing duty cycles
    output reg pulse
);
    reg [7:0] counter;
    reg [7:0] duty_threshold;
    
    // 添加高扇出信号缓冲寄存器
    reg [7:0] period_buf1, period_buf2;
    reg [7:0] counter_buf1, counter_buf2;
    reg b0; // 为pulse逻辑添加中间寄存器
    
    // 为period信号添加双级缓冲
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            period_buf1 <= 8'd0;
            period_buf2 <= 8'd0;
        end else begin
            period_buf1 <= period;
            period_buf2 <= period_buf1;
        end
    end
    
    // 为counter添加缓冲寄存器
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            counter_buf1 <= 8'd0;
            counter_buf2 <= 8'd0;
        end else begin
            counter_buf1 <= counter;
            counter_buf2 <= counter_buf1;
        end
    end
    
    // 主状态逻辑
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            counter <= 8'd0;
            duty_threshold <= 8'd0;
            b0 <= 1'b0;
        end else begin
            // 使用缓冲的period信号计算duty_threshold
            case (duty_sel)
                3'd0: duty_threshold <= {1'b0, period_buf1[7:1]};      // 50%
                3'd1: duty_threshold <= {2'b00, period_buf1[7:2]};     // 25%
                3'd2: duty_threshold <= {3'b000, period_buf1[7:3]};    // 12.5%
                3'd3: duty_threshold <= {2'b00, period_buf1[7:2]} + {1'b0, period_buf2[7:1]}; // 75%
                3'd4: duty_threshold <= {3'b000, period_buf1[7:3]} + {1'b0, period_buf2[7:1]}; // 62.5%
                3'd5: duty_threshold <= {3'b000, period_buf1[7:3]} + {2'b00, period_buf2[7:2]}; // 37.5%
                3'd6: duty_threshold <= period_buf1 - 8'd1;           // 99%
                3'd7: duty_threshold <= 8'd1;                         // 1%
            endcase
            
            // 使用缓冲的period信号处理counter逻辑
            if (counter >= period_buf2-1)
                counter <= 8'd0;
            else
                counter <= counter + 8'd1;
                
            // 使用缓冲的counter信号计算中间结果
            b0 <= (counter_buf1 < duty_threshold) ? 1'b1 : 1'b0;
        end
    end
    
    // 输出逻辑，使用中间结果寄存器
    always @(posedge clk or posedge arst) begin
        if (arst)
            pulse <= 1'b0;
        else
            pulse <= b0;
    end
endmodule