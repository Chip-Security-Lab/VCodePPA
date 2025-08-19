//SystemVerilog
module dual_sampler (
    input clk, din,
    output reg rise_data, fall_data
);
    // 引入输入缓冲，减少输入到寄存器的延迟
    wire din_buffered;
    assign din_buffered = din;
    
    // 在上升沿采样
    always @(posedge clk) 
        rise_data <= din_buffered;
    
    // 在下降沿采样
    always @(negedge clk) 
        fall_data <= din_buffered;
endmodule