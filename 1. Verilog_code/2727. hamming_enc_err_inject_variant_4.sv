//SystemVerilog
module hamming_enc_err_inject(
    input clk, rst,
    input [3:0] data,
    input valid,          // 数据有效信号，替代原来的req
    output reg ready,     // 准备接收信号，替代原来的ack
    input inject_error,
    input [2:0] error_pos,
    output reg [6:0] encoded,
    output reg encoded_valid  // 输出数据有效信号
);
    reg [6:0] normal_encoded;
    reg processing;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            normal_encoded <= 7'b0;
            ready <= 1'b1;
            encoded_valid <= 1'b0;
            processing <= 1'b0;
        end else begin
            if (valid && ready) begin
                // 接收新数据并开始处理
                normal_encoded[0] <= data[0] ^ data[1] ^ data[3];
                normal_encoded[1] <= data[0] ^ data[2] ^ data[3];
                normal_encoded[2] <= data[0];
                normal_encoded[3] <= data[1] ^ data[2] ^ data[3];
                normal_encoded[4] <= data[1];
                normal_encoded[5] <= data[2];
                normal_encoded[6] <= data[3];
                ready <= 1'b0;
                processing <= 1'b1;
            end else if (processing) begin
                // 处理完成
                encoded <= inject_error ? normal_encoded ^ (1 << error_pos) : normal_encoded;
                encoded_valid <= 1'b1;
                processing <= 1'b0;
            end else if (encoded_valid) begin
                // 等待下一次传输
                encoded_valid <= 1'b0;
                ready <= 1'b1;
            end
        end
    end
endmodule