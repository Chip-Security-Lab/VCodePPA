//SystemVerilog
module s2p_buffer (
    input wire clk,
    input wire serial_in,
    input wire req,      // 替代原来的shift信号
    input wire clear,
    output reg [7:0] parallel_out,
    output reg ack       // 新增的应答信号
);
    // 内部状态和数据寄存器
    reg req_r;
    reg serial_in_r;     // 寄存器化输入数据
    
    // IEEE 1364-2005 Verilog标准
    // 输入数据寄存化处理
    always @(posedge clk) begin
        if (clear) begin
            serial_in_r <= 1'b0;
            req_r <= 1'b0;
        end
        else begin
            serial_in_r <= serial_in;
            req_r <= req;
        end
    end
    
    // 状态及输出处理
    always @(posedge clk) begin
        if (clear) begin
            parallel_out <= 8'b0;
            ack <= 1'b0;
        end
        else begin
            // 检测req上升沿(新请求)
            if (req && !req_r) begin
                parallel_out <= {parallel_out[6:0], serial_in_r};
                ack <= 1'b1;  // 发送确认信号
            end
            else if (!req && req_r) begin
                ack <= 1'b0;  // 复位ack，等待下一个请求
            end
        end
    end
endmodule