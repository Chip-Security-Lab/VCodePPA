//SystemVerilog
module fp2fix_sync #(
    parameter Q = 8
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] fp,
    output reg  [30:0] fixed
);

wire sign_fp;
wire [7:0] exp_fp_unsigned;
wire signed [8:0] exp_fp;
wire [23:0] mant_fp;
wire [30:0] fixed_comb;

assign sign_fp = fp[31];
assign exp_fp_unsigned = fp[30:23];
assign exp_fp = $signed({1'b0, exp_fp_unsigned}) - 127;
assign mant_fp = {1'b1, fp[22:0]};

// 32位借位减法器实现
function [31:0] borrow_subtractor_32;
    input [31:0] minuend;
    input [31:0] subtrahend;
    integer i;
    reg [31:0] diff;
    reg borrow;
    begin
        borrow = 1'b0;
        for (i=0; i<32; i=i+1) begin
            diff[i] = minuend[i] ^ subtrahend[i] ^ borrow;
            borrow = (~minuend[i] & subtrahend[i]) | ((~minuend[i] | subtrahend[i]) & borrow);
        end
        borrow_subtractor_32 = diff;
    end
endfunction

// 移位操作
wire signed [31:0] mantissa_shifted;
assign mantissa_shifted = $signed(mant_fp) <<< (exp_fp - Q);

// 负数取反加一使用借位减法器实现
wire [31:0] mantissa_shifted_abs;
wire [31:0] mantissa_shifted_neg;
assign mantissa_shifted_abs = mantissa_shifted[31] ? borrow_subtractor_32(32'b0, mantissa_shifted) : mantissa_shifted;
assign mantissa_shifted_neg = borrow_subtractor_32(32'b0, mantissa_shifted);

// fixed_comb生成
assign fixed_comb = sign_fp ? mantissa_shifted_neg[30:0] : mantissa_shifted[30:0];

// 一级寄存器
reg [30:0] fixed_buf1;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        fixed_buf1 <= 31'b0;
    end else begin
        fixed_buf1 <= fixed_comb;
    end
end

// 二级寄存器
reg [30:0] fixed_buf2;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        fixed_buf2 <= 31'b0;
    end else begin
        fixed_buf2 <= fixed_buf1;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        fixed <= 31'b0;
    end else begin
        fixed <= fixed_buf2;
    end
end

endmodule