//SystemVerilog
module interleave_shift #(parameter W=8) (
    input clk,
    input [W-1:0] din,
    output reg [W-1:0] dout
);

// 一级缓冲寄存器，减少din高扇出延迟
reg [W-1:0] din_buf1;
reg [W-1:0] din_buf2;

// 二级缓冲寄存器，均衡din_buf2的高扇出负载
reg din_buf2_buf_0;
reg din_buf2_buf_1;
reg din_buf2_buf_2;
reg din_buf2_buf_3;
reg din_buf2_buf_4;
reg din_buf2_buf_5;
reg din_buf2_buf_6;
reg din_buf2_buf_7;

always @(posedge clk) begin
    din_buf1 <= din;
    din_buf2 <= din_buf1;
end

always @(posedge clk) begin
    din_buf2_buf_0 <= din_buf2[0];
    din_buf2_buf_1 <= din_buf2[1];
    din_buf2_buf_2 <= din_buf2[2];
    din_buf2_buf_3 <= din_buf2[3];
    din_buf2_buf_4 <= din_buf2[4];
    din_buf2_buf_5 <= din_buf2[5];
    din_buf2_buf_6 <= din_buf2[6];
    din_buf2_buf_7 <= din_buf2[7];
end

always @(posedge clk) begin
    dout <= {din_buf2_buf_6, din_buf2_buf_4, din_buf2_buf_2, din_buf2_buf_0,
             din_buf2_buf_7, din_buf2_buf_5, din_buf2_buf_3, din_buf2_buf_1};
end

endmodule