//SystemVerilog
module precision_pulse_gen #(
    parameter CLK_FREQ_HZ = 100000000,
    parameter PULSE_US = 10
)(
    input clk,
    input rst_n,
    input trigger,
    output reg pulse_out
);
    localparam COUNT = (CLK_FREQ_HZ / 1000000) * PULSE_US;
    localparam CNT_WIDTH = $clog2(COUNT);
    
    reg [CNT_WIDTH-1:0] counter;
    reg active;
    wire counter_done;
    
    // 使用专用的比较信号提前计算比较结果
    assign counter_done = (counter >= COUNT-1);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            pulse_out <= 0;
            active <= 0;
        end else begin
            // 优化分支逻辑，减少嵌套比较
            case ({trigger, active})
                2'b10, 2'b11: begin  // 触发优先，允许重触发
                    if (!active) begin
                        active <= 1'b1;
                        pulse_out <= 1'b1;
                        counter <= 0;
                    end else if (counter_done) begin
                        pulse_out <= 1'b0;
                        active <= 1'b0;
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end
                
                2'b01: begin  // 活动状态，无触发
                    if (counter_done) begin
                        pulse_out <= 1'b0;
                        active <= 1'b0;
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end
                
                default: begin  // 2'b00: 空闲状态
                    // 保持当前状态
                end
            endcase
        end
    end
endmodule