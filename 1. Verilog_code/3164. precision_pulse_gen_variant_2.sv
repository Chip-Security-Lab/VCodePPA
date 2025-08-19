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
    localparam COUNTER_WIDTH = $clog2(COUNT);
    
    reg [COUNTER_WIDTH-1:0] counter;
    reg trigger_r;
    wire trigger_rising_edge;
    wire counter_max;
    wire counter_nonzero;
    wire counter_next;
    
    // 提前计算关键路径信号
    assign counter_max = (counter == COUNT-1);
    assign counter_nonzero = |counter;
    assign counter_next = counter + 1'b1;
    
    // 检测触发信号的上升沿
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            trigger_r <= 1'b0;
        else
            trigger_r <= trigger;
    end
    
    assign trigger_rising_edge = trigger && !trigger_r;
    
    // 优化后的脉冲生成逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            pulse_out <= 1'b0;
        end else if (trigger_rising_edge) begin
            counter <= {{(COUNTER_WIDTH-1){1'b0}}, 1'b1};
            pulse_out <= 1'b1;
        end else if (counter_nonzero) begin
            counter <= counter_max ? {COUNTER_WIDTH{1'b0}} : counter_next;
            pulse_out <= !counter_max;
        end
    end
endmodule