//SystemVerilog
module BidirectionalPISO #(parameter WIDTH=8) (
    input clk, load, left_right,
    input [WIDTH-1:0] parallel_in,
    output serial_out
);
    // 前向寄存器重定时：移动输出寄存器到组合逻辑前
    reg [WIDTH-1:0] buffer;
    wire next_bit;
    
    // 组合逻辑确定输出位
    assign next_bit = left_right ? buffer[WIDTH-1] : buffer[0];
    
    // 输出赋值
    assign serial_out = next_bit;
    
    always @(posedge clk) begin
        if (load) 
            buffer <= parallel_in;
        else 
            buffer <= left_right ? {buffer[WIDTH-2:0], 1'b0} : {1'b0, buffer[WIDTH-1:1]};
    end
endmodule