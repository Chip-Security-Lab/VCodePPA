//SystemVerilog
module single_pulse_gen #(
    parameter DELAY_CYCLES = 50
)(
    input clk,
    input trigger,
    output pulse
);

// 优化重定时的寄存器和信号
reg [31:0] counter;
reg state;
reg pulse_out;

// 将组合逻辑移到寄存器前面
wire trigger_detected = trigger && (state == 0);
wire counting_done = (counter == 1) && (state == 1);
wire counting = (counter > 0) && (state == 1);

// 新的组合逻辑结构，减少关键路径延迟
wire [31:0] counter_next = counting ? (counter - 1) : 
                          trigger_detected ? DELAY_CYCLES : 
                          counter;

wire state_next = trigger_detected ? 1'b1 :
                 counting_done ? 1'b0 :
                 state;

wire pulse_next = counting_done;

// 单级流水线寄存器，优化后的前向重定时结构
always @(posedge clk) begin
    counter <= counter_next;
    state <= state_next;
    pulse_out <= pulse_next;
end

// 输出赋值
assign pulse = pulse_out;

endmodule