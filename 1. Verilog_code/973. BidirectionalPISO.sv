module BidirectionalPISO #(parameter WIDTH=8) (
    input clk, load, left_right,
    input [WIDTH-1:0] parallel_in,
    output serial_out // 移除reg
);
reg [WIDTH-1:0] buffer;
reg out_bit; // 添加中间寄存器

always @(posedge clk) begin
    if (load) buffer <= parallel_in;
    else buffer <= left_right ? {buffer[WIDTH-2:0], 1'b0} : {1'b0, buffer[WIDTH-1:1]};
    
    // 在时钟边沿更新输出位
    out_bit <= left_right ? buffer[WIDTH-1] : buffer[0];
end

assign serial_out = out_bit;
endmodule