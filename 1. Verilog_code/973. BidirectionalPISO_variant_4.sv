//SystemVerilog
module BidirectionalPISO #(parameter WIDTH=8) (
    input clk, load, left_right,
    input [WIDTH-1:0] parallel_in,
    output serial_out
);
    // 内部信号定义
    reg [WIDTH-1:0] buffer;
    reg left_out_bit, right_out_bit;
    
    // 组合逻辑信号
    wire [WIDTH-1:0] next_buffer;
    wire next_left_out_bit;
    wire next_right_out_bit;
    
    // 组合逻辑部分 - 移位寄存器逻辑
    assign next_buffer = load ? parallel_in : 
                        (left_right ? {buffer[WIDTH-2:0], 1'b0} : 
                                     {1'b0, buffer[WIDTH-1:1]});
    
    // 组合逻辑部分 - 提取输出位
    assign next_left_out_bit = buffer[WIDTH-1];
    assign next_right_out_bit = buffer[0];
    
    // 组合逻辑部分 - 输出选择
    assign serial_out = left_right ? left_out_bit : right_out_bit;
    
    // 时序逻辑部分 - 全部时序逻辑集中
    always @(posedge clk) begin
        // 移位寄存器更新
        buffer <= next_buffer;
        
        // 左右输出位寄存
        left_out_bit <= next_left_out_bit;
        right_out_bit <= next_right_out_bit;
    end
endmodule