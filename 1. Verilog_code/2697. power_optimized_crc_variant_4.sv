//SystemVerilog
module power_optimized_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire data_req,
    input wire power_save,
    output reg [7:0] crc,
    output reg data_ack
);
    parameter [7:0] POLY = 8'h07;
    reg processing;
    
    // 使用时钟门控单元替代简单的与门以减少毛刺
    wire gated_clk;
    
    // 时钟门控单元实现
    reg clk_en_latch;
    always @(negedge clk or posedge rst) begin
        if (rst)
            clk_en_latch <= 1'b0;
        else
            clk_en_latch <= ~power_save;
    end
    
    assign gated_clk = clk & clk_en_latch;
    
    // 简化CRC计算逻辑，优化布尔表达式
    wire crc_feedback = crc[7] ^ data[0];
    wire [7:0] next_crc = {crc[6:0], 1'b0} ^ (crc_feedback ? POLY : 8'h00);
    
    always @(posedge gated_clk or posedge rst) begin
        if (rst) begin
            crc <= 8'h00;
            data_ack <= 1'b0;
            processing <= 1'b0;
        end
        else begin
            if (data_req & ~processing) begin
                // 处理请求
                crc <= next_crc;
                data_ack <= 1'b1;
                processing <= 1'b1;
            end
            else if (~data_req & processing) begin
                // 复位应答信号
                data_ack <= 1'b0;
                processing <= 1'b0;
            end
        end
    end
endmodule