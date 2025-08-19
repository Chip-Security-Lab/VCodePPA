//SystemVerilog
module Comparator_PulseGen #(parameter WIDTH = 8) (
    input              clk,
    input  [WIDTH-1:0] data_x,
    input  [WIDTH-1:0] data_y,
    output             change_pulse
);
    reg last_state;
    wire curr_state;
    
    // 先行借位减法器实现
    wire [WIDTH-1:0] borrow;
    wire [WIDTH-1:0] diff;
    
    // 生成借位和差值
    assign borrow[0] = (data_x[0] < data_y[0]) ? 1'b1 : 1'b0;
    assign diff[0] = data_x[0] ^ data_y[0];
    
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin: gen_borrow
            assign borrow[i] = (data_x[i] < data_y[i]) ? 1'b1 : 
                              ((data_x[i] == data_y[i]) && borrow[i-1]) ? 1'b1 : 1'b0;
            assign diff[i] = data_x[i] ^ data_y[i] ^ borrow[i-1];
        end
    endgenerate
    
    // 比较结果：如果diff全为0且最终没有借位，则相等
    assign curr_state = (diff == {WIDTH{1'b0}}) && (borrow[WIDTH-1] == 1'b0);
    
    always @(posedge clk) 
        last_state <= curr_state;
    
    // 检测状态变化沿
    assign change_pulse = (curr_state != last_state);
endmodule