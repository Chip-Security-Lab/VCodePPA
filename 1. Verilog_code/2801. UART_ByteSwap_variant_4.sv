//SystemVerilog
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

// 字节交换功能函数
function [7:0] swap_bytes;
    input [7:0] data_in;
    reg [3:0] idx;
    begin
        for (idx = 0; idx < 8; idx = idx + 1)
            swap_bytes[idx] = data_in[7 - idx];
    end
endfunction

//-----------------------------
// TX数据选择逻辑
//-----------------------------
// 功能：根据SWAP_ENABLE和swap_en选择是否发送交换后的tx_native
always @(*) begin
    if (SWAP_ENABLE && swap_en)
        tx_data = swap_bytes(tx_native);
    else
        tx_data = tx_native;
end

generate
    if (GROUP_SIZE > 1) begin : gen_group_swap

        // 交换缓存
        reg [7:0] swap_buffer [0:GROUP_SIZE-1];
        // 接收缓冲
        reg [7:0] rx_buffer [0:GROUP_SIZE-1];
        integer swap_idx;
        integer buf_idx;

        //-----------------------------
        // RX数据交换组合逻辑
        //-----------------------------
        // 功能：将输入rx_data经过swap_en控制的swap_bytes组合逻辑后送入swap_buffer
        always @(*) begin
            for (swap_idx = 0; swap_idx < GROUP_SIZE; swap_idx = swap_idx + 1) begin
                if (swap_en)
                    swap_buffer[swap_idx] = swap_bytes(rx_data);
                else
                    swap_buffer[swap_idx] = rx_data;
            end
        end

        //-----------------------------
        // RX缓冲区写入
        //-----------------------------
        // 功能：在rx_done时，把swap_buffer逆序写入rx_buffer
        always @(posedge clk) begin
            if (rx_done) begin
                for (buf_idx = 0; buf_idx < GROUP_SIZE; buf_idx = buf_idx + 1)
                    rx_buffer[buf_idx] <= swap_buffer[GROUP_SIZE-1-buf_idx];
            end
        end

        //-----------------------------
        // RX输出数据逻辑
        //-----------------------------
        // 功能：在rx_done时输出rx_buffer[0]到rx_swapped
        always @(posedge clk) begin
            if (rx_done)
                rx_swapped <= rx_buffer[0];
        end

    end else begin : gen_single_swap

        //-----------------------------
        // RX数据交换组合逻辑
        //-----------------------------
        // 功能：将输入rx_data经过swap_en控制的swap_bytes组合逻辑
        wire [7:0] swapped_data;
        assign swapped_data = swap_en ? swap_bytes(rx_data) : rx_data;

        //-----------------------------
        // RX输出数据逻辑
        //-----------------------------
        // 功能：在rx_done时输出组合逻辑后的swapped_data
        always @(posedge clk) begin
            if (rx_done)
                rx_swapped <= swapped_data;
        end

    end
endgenerate

endmodule