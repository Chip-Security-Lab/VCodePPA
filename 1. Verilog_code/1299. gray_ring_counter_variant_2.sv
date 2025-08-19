//SystemVerilog
module gray_ring_counter (
    input clk, rst_n,
    input ack,
    output reg req,
    output reg [3:0] gray_out
);

    reg [3:0] next_gray;
    reg transfer_done;
    
    // 计算下一个格雷码值
    always @(*) begin
        next_gray = {gray_out[0], gray_out[3:1] ^ {2'b00, gray_out[0]}};
    end
    
    // 处理gray_out输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_out <= 4'b0001;
        end else if (!transfer_done && req && ack) begin
            gray_out <= next_gray;
        end
    end
    
    // 处理req请求信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req <= 1'b0;
        end else if (!transfer_done) begin
            if (!req) begin
                req <= 1'b1;
            end else if (req && ack) begin
                req <= 1'b0;
            end
        end
    end
    
    // 处理传输完成状态
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            transfer_done <= 1'b0;
        end else if (!transfer_done && req && ack) begin
            transfer_done <= 1'b1;
        end else if (transfer_done && !ack) begin
            transfer_done <= 1'b0;
        end
    end

endmodule