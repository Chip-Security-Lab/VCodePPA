//SystemVerilog
module Hamming7_4_Encoder_Sync (
    input clk,            // 系统时钟
    input rst_n,          // 异步低复位
    input [3:0] data_in,  // 4位输入数据
    output reg [6:0] code_out // 7位编码输出
);

// 缓冲寄存器用于高扇出信号data_in
reg [3:0] data_in_buf1, data_in_buf2;
// 中间编码结果寄存器
reg [6:0] code_out_int;

// 第一级：输入数据缓冲
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_in_buf1 <= 4'b0;
        data_in_buf2 <= 4'b0;
    end else begin
        data_in_buf1 <= data_in;
        data_in_buf2 <= data_in;
    end
end

// 第二级：计算编码并存入中间寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        code_out_int <= 7'b0;
    end else begin
        code_out_int[6:4] <= data_in_buf1[3:1];
        code_out_int[3]   <= data_in_buf1[3] ^ data_in_buf1[2] ^ data_in_buf1[0];
        code_out_int[2]   <= data_in_buf1[3] ^ data_in_buf1[1] ^ data_in_buf1[0];
        code_out_int[1]   <= data_in_buf2[2] ^ data_in_buf2[1] ^ data_in_buf2[0];
        code_out_int[0]   <= data_in_buf2[0];
    end
end

// 第三级：输出寄存器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        code_out <= 7'b0;
    end else begin
        code_out <= code_out_int;
    end
end

endmodule