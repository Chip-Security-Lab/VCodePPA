//SystemVerilog
module Comparator_PulseGen #(parameter WIDTH = 8) (
    input              clk,
    input  [WIDTH-1:0] data_x,
    input  [WIDTH-1:0] data_y,
    output             change_pulse
);
    // 直接比较输入数据，移除输入寄存
    wire curr_compare = (data_x == data_y);
    
    // 移动寄存器到组合逻辑之后
    reg curr_state;
    reg last_state;
    
    always @(posedge clk) begin
        // 寄存比较结果而非输入
        curr_state <= curr_compare;
        last_state <= curr_state;
    end
    
    // 检测状态变化沿
    assign change_pulse = (curr_state != last_state);
endmodule