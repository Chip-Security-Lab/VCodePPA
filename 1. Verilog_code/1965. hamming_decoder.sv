module hamming_decoder(
    input [6:0] hamming_in,  // 7位汉明码 [p1,p2,d1,p3,d2,d3,d4]
    output [3:0] data_out,   // 4位纠错后的数据
    output error_detected    // 错误指示
);
    wire [6:0] h = hamming_in;
    wire [2:0] syndrome;
    
    // 计算校验位
    assign syndrome[0] = h[0] ^ h[2] ^ h[4] ^ h[6];
    assign syndrome[1] = h[1] ^ h[2] ^ h[5] ^ h[6];
    assign syndrome[2] = h[3] ^ h[4] ^ h[5] ^ h[6];
    
    // 错误检测
    assign error_detected = |syndrome;
    
    // 数据提取与纠错
    assign data_out[0] = (syndrome == 3'b101) ? ~h[2] : h[2];
    assign data_out[1] = (syndrome == 3'b110) ? ~h[4] : h[4];
    assign data_out[2] = (syndrome == 3'b011) ? ~h[5] : h[5];
    assign data_out[3] = (syndrome == 3'b111) ? ~h[6] : h[6];
endmodule