module Comparator_PulseGen #(parameter WIDTH = 8) (
    input              clk,
    input  [WIDTH-1:0] data_x,
    input  [WIDTH-1:0] data_y,
    output             change_pulse
);
    reg last_state;
    wire curr_state = (data_x == data_y);
    
    always @(posedge clk) last_state <= curr_state;
    
    // 检测状态变化沿
    assign change_pulse = (curr_state != last_state);
endmodule