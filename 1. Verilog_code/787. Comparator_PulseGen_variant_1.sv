//SystemVerilog
module Comparator_PulseGen #(parameter WIDTH = 8) (
    input              clk,
    input  [WIDTH-1:0] data_x,
    input  [WIDTH-1:0] data_y,
    output             change_pulse
);
    // 直接比较两个输入是否相等
    wire curr_state;
    reg last_state;
    
    // 使用相等比较运算符直接比较，更高效
    assign curr_state = (data_x == data_y);
    
    // 寄存器逻辑
    always @(posedge clk) 
        last_state <= curr_state;
    
    // 使用异或来检测状态变化，比较高效
    assign change_pulse = curr_state ^ last_state;
endmodule