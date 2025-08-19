module decoder_graycode #(parameter AW=4) (
    input [AW-1:0] bin_addr,
    output [2**AW-1:0] decoded
);
    wire [AW-1:0] gray_addr = bin_addr ^ (bin_addr >> 1); // 二进制转格雷码
    assign decoded = 1'b1 << gray_addr;
endmodule