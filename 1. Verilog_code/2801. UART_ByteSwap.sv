module UART_ByteSwap #(
    parameter SWAP_ENABLE = 1,
    parameter GROUP_SIZE = 2
)(
    input  wire         clk,        
    input  wire         swap_en,    
    output reg  [7:0]   rx_swapped,
    input  wire [7:0]   tx_native,
    output reg  [7:0]   tx_data,    
    input  wire [7:0]   rx_data,    
    input  wire         rx_done     
);
// 字节重排序逻辑
function [7:0] swap_bytes;
    input [7:0] data;
    reg [3:0] i;      
    begin
        for (i=0; i<8; i=i+1)  
            swap_bytes[i] = data[7-i];
    end
endfunction

// 发送端处理
always @(*) begin
    tx_data = (SWAP_ENABLE && swap_en) ? 
              swap_bytes(tx_native) : tx_native;
end

// 接收端处理
generate
    if (GROUP_SIZE > 1) begin : group_swap
        reg [7:0] rx_buffer [0:GROUP_SIZE-1];
        reg [7:0] swap_buffer [0:GROUP_SIZE-1];
        integer i;
        
        always @(posedge clk) begin
            if (rx_done) begin
                for (i=0; i<GROUP_SIZE; i=i+1)
                    // 修复：rx_swapped是8位寄存器，不能按多字节数组访问
                    rx_buffer[i] = swap_buffer[GROUP_SIZE-1-i];
                rx_swapped <= rx_buffer[0]; // 只输出第一个字节
            end
        end
    end else begin : single_swap
        always @(posedge clk) begin
            if (rx_done)
                rx_swapped <= swap_en ? swap_bytes(rx_data) : rx_data;
        end
    end
endgenerate
endmodule