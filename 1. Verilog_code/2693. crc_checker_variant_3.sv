//SystemVerilog
module crc_checker(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire [7:0] crc_in,
    input wire data_req,    // 替换原来的 data_valid
    output reg crc_ack,     // 替换原来的 crc_valid
    output reg [7:0] calculated_crc
);
    parameter [7:0] POLY = 8'hD5;
    
    // 添加缓冲寄存器以降低calculated_crc的扇出负载
    reg [7:0] calculated_crc_buf1;
    reg [7:0] calculated_crc_buf2;
    
    // 添加请求-应答状态机所需的信号
    reg data_req_d;         // 延迟 data_req 以检测边沿
    reg processing;         // 数据处理状态
    reg crc_result_ready;   // CRC 计算结果就绪
    
    wire [7:0] next_crc;
    wire crc_feedback = calculated_crc_buf1[7] ^ data_in[0];
    wire [7:0] poly_term = crc_feedback ? POLY : 8'h00;
    
    assign next_crc = {calculated_crc_buf1[6:0], 1'b0} ^ poly_term;
    
    // 检测请求信号的上升沿
    always @(posedge clk) begin
        if (rst) begin
            data_req_d <= 1'b0;
        end else begin
            data_req_d <= data_req;
        end
    end
    
    wire req_rising_edge = data_req & ~data_req_d;
    
    always @(posedge clk) begin
        if (rst) begin
            calculated_crc <= 8'h00;
            calculated_crc_buf1 <= 8'h00;
            calculated_crc_buf2 <= 8'h00;
            crc_ack <= 1'b0;
            processing <= 1'b0;
            crc_result_ready <= 1'b0;
        end else begin
            // 检测请求的上升沿，开始处理
            if (req_rising_edge && !processing) begin
                processing <= 1'b1;
                calculated_crc <= next_crc;
                calculated_crc_buf1 <= calculated_crc;
                calculated_crc_buf2 <= calculated_crc;
                crc_result_ready <= 1'b1;
            end
            
            // 当处理完成，输出应答信号
            if (processing && crc_result_ready) begin
                crc_ack <= (calculated_crc_buf2 == crc_in);
                processing <= 1'b0;
                crc_result_ready <= 1'b0;
            end
            
            // 当请求信号撤销，清除应答信号
            if (!data_req && crc_ack) begin
                crc_ack <= 1'b0;
            end
        end
    end
endmodule