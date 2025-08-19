module UART_MultiBuffer #(
    parameter BUFFER_LEVEL = 4
)(
    input wire clk,               // 添加时钟输入
    input wire [7:0] rx_data,     // 添加接收数据输入
    input wire rx_valid,          // 添加数据有效信号
    output wire [7:0] buffer_occupancy,
    input wire buffer_flush       // 缓冲区清空信号
);
// 多级流水寄存器
reg [7:0] data_pipe [0:BUFFER_LEVEL-1];
reg [3:0] valid_pipe;
integer i; // 用于for循环

always @(posedge clk) begin
    // 数据流水传递 - 使用标准Verilog而非SystemVerilog
    if (buffer_flush) begin
        valid_pipe <= 4'b0;
    end else begin
        // 数据流水传递
        for (i = BUFFER_LEVEL-1; i > 0; i = i - 1)
            data_pipe[i] <= data_pipe[i-1];
        data_pipe[0] <= rx_data;

        // 有效位传递
        valid_pipe <= {valid_pipe[2:0], rx_valid};
    end
end

// 水位检测
assign buffer_occupancy = {4'b0, valid_pipe};
endmodule