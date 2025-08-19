//SystemVerilog
module multichannel_buffer (
    input wire clk,
    input wire [3:0] channel_select,
    input wire [7:0] data_in,
    input wire write_en,
    output reg [7:0] data_out
);
    reg [7:0] channels [0:15];
    reg [3:0] channel_select_reg;
    
    // 合并所有时序逻辑到一个always块中，减少资源使用并提高时序性能
    always @(posedge clk) begin
        // 寄存通道选择信号
        channel_select_reg <= channel_select;
        
        // 处理写入操作
        if (write_en)
            channels[channel_select] <= data_in;
            
        // 读取数据到输出寄存器
        data_out <= channels[channel_select_reg];
    end
endmodule