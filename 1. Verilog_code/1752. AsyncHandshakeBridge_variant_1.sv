//SystemVerilog
module AsyncHandshakeBridge(
    input src_clk, dst_clk,
    input req_in, ack_out,
    output reg req_out, ack_in,
    input [31:0] data_in,
    output reg [31:0] data_out
);
    // 源时钟域信号
    reg [31:0] src_data_buf;
    reg src_valid;
    reg src_handshake_flag;
    
    // 目标时钟域信号
    reg [31:0] dst_data_buf;
    reg dst_valid;
    reg dst_req; 
    
    // CDC同步器 - 源到目标
    reg src_flag_sync1, src_flag_sync2, src_flag_sync3;
    reg dst_data_ready;
    
    // CDC同步器 - 目标到源
    reg ack_sync1, ack_sync2;
    
    // 第1阶段：源时钟域 - 输入数据捕获
    always @(posedge src_clk) begin
        if (req_in && !ack_sync2) begin
            src_data_buf <= data_in;
            src_valid <= 1'b1;
        end else if (ack_sync2) begin
            src_valid <= 1'b0;
        end
    end
    
    // 第2阶段：源时钟域 - 握手标志控制
    always @(posedge src_clk) begin
        if (req_in && !ack_sync2 && src_valid) begin
            src_handshake_flag <= ~src_handshake_flag;
        end
    end
    
    // 第3阶段：目标时钟域 - 同步源握手标志
    always @(posedge dst_clk) begin
        src_flag_sync1 <= src_handshake_flag;
        src_flag_sync2 <= src_flag_sync1;
        src_flag_sync3 <= src_flag_sync2;
    end
    
    // 第4阶段：目标时钟域 - 检测边沿变化
    always @(posedge dst_clk) begin
        if (src_flag_sync2 != src_flag_sync3) begin
            dst_data_ready <= 1'b1;
        end else begin
            dst_data_ready <= 1'b0;
        end
    end
    
    // 第5阶段：目标时钟域 - 数据传输和请求生成
    always @(posedge dst_clk) begin
        if (dst_data_ready) begin
            dst_data_buf <= src_data_buf;
            dst_valid <= 1'b1;
            dst_req <= 1'b1;
        end else if (ack_out) begin
            dst_valid <= 1'b0;
            dst_req <= 1'b0;
        end
    end
    
    // 第6阶段：目标时钟域 - 输出控制
    always @(posedge dst_clk) begin
        if (dst_valid) begin
            data_out <= dst_data_buf;
            req_out <= dst_req;
        end else begin
            req_out <= 1'b0;
        end
    end
    
    // 第7阶段：目标时钟域 - 确认信号生成
    always @(posedge dst_clk) begin
        if (dst_valid && dst_req) begin
            ack_in <= 1'b1;
        end else begin
            ack_in <= 1'b0;
        end
    end
    
    // 第8阶段：源时钟域 - 同步确认信号
    always @(posedge src_clk) begin
        ack_sync1 <= ack_in;
        ack_sync2 <= ack_sync1;
    end
    
endmodule