//SystemVerilog
//IEEE 1364-2005 Verilog
module autoincrement_buffer (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid,     // 发送方数据有效信号
    input wire data_ready,     // 接收方准备好接收数据信号
    output reg [7:0] data_out,
    output reg data_out_valid  // 输出数据有效信号
);
    // 存储单元定义
    reg [7:0] memory [0:15];
    
    // 地址控制部分
    reg [3:0] write_addr;
    reg [3:0] read_addr;
    
    // 内部流水线控制信号
    reg write_pending;
    reg [7:0] data_in_reg;
    
    // 写入握手信号 - 当data_valid为高且写入通道未被占用时发生
    wire write_handshake;
    assign write_handshake = data_valid && !write_pending;
    
    // 读出握手信号 - 当data_out_valid和data_ready同时为高时发生
    wire read_handshake;
    assign read_handshake = data_out_valid && data_ready;
    
    // 缓冲区状态控制
    reg [4:0] buffer_count; // 比地址多一位以区分空和满
    wire buffer_empty;
    wire buffer_full;
    
    assign buffer_empty = (buffer_count == 0);
    assign buffer_full = (buffer_count == 16); // 缓冲区大小为16
    
    // 缓冲区计数逻辑
    always @(posedge clk) begin
        if (rst) begin
            buffer_count <= 5'd0;
        end 
        else begin
            case ({write_handshake, read_handshake})
                2'b10: buffer_count <= buffer_count + 1'b1; // 只写入
                2'b01: buffer_count <= buffer_count - 1'b1; // 只读出
                default: buffer_count <= buffer_count;      // 同时读写或无操作
            endcase
        end
    end
    
    // 写地址控制逻辑
    always @(posedge clk) begin
        if (rst) begin
            write_addr <= 4'b0;
            write_pending <= 1'b0;
            data_in_reg <= 8'b0;
        end 
        else begin
            // 写入握手发生时
            if (write_handshake) begin
                memory[write_addr] <= data_in; // 直接写入存储器
                write_addr <= write_addr + 1'b1;
                write_pending <= 1'b1;
                data_in_reg <= data_in;
            end 
            else if (write_pending) begin
                write_pending <= 1'b0; // 清除挂起状态，允许下一次写入
            end
        end
    end
    
    // 读地址控制和数据输出逻辑
    always @(posedge clk) begin
        if (rst) begin
            read_addr <= 4'b0;
            data_out <= 8'b0;
            data_out_valid <= 1'b0;
        end 
        else begin
            if (read_handshake) begin
                if (!buffer_empty) begin
                    // 读取下一个数据
                    data_out <= memory[read_addr + 1'b1];
                    read_addr <= read_addr + 1'b1;
                    data_out_valid <= 1'b1;
                end 
                else begin
                    // 没有更多数据可读
                    data_out_valid <= 1'b0;
                end
            end 
            else if (!data_out_valid && !buffer_empty) begin
                // 有数据可读但尚未输出
                data_out <= memory[read_addr];
                data_out_valid <= 1'b1;
            end
        end
    end
    
endmodule