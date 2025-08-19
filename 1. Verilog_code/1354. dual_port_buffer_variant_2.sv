//SystemVerilog
module dual_port_buffer (
    input wire clk,
    input wire [31:0] write_data,
    input wire write_req,
    output reg write_ack,
    output reg read_req,
    input wire read_ack,
    output reg [31:0] read_data
);
    reg [31:0] buffer;
    reg data_available;
    reg write_pending;
    
    // 请求-应答握手接口逻辑
    always @(posedge clk) begin
        // 默认状态
        write_ack <= 1'b0;
        
        // 写入请求处理
        if (write_req && !write_pending) begin
            if (!data_available || read_ack) begin
                // 可以立即写入
                buffer <= write_data;
                write_ack <= 1'b1;
                data_available <= 1'b1;
                write_pending <= 1'b0;
            end else begin
                // 缓冲区满且未被读取，等待
                write_pending <= 1'b1;
            end
        end
        
        // 当缓冲区空出时处理挂起的写入请求
        if (write_pending && read_ack) begin
            buffer <= write_data;
            write_ack <= 1'b1;
            data_available <= 1'b1;
            write_pending <= 1'b0;
        end
        
        // 读取请求生成
        read_req <= data_available && !read_ack;
        
        // 读取确认处理
        if (read_req && read_ack) begin
            read_data <= buffer;
            data_available <= write_req && write_ack;
        end
    end
endmodule