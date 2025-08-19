module hamming_encoder(
    input [3:0] data_in,  // 4位数据
    output [6:0] hamming_out  // 7位汉明码 [p1,p2,d1,p3,d2,d3,d4]
);
    wire [3:0] d = data_in;
    wire p1, p2, p3;
    
    // 计算奇偶校验位
    assign p1 = d[0] ^ d[1] ^ d[3];
    assign p2 = d[0] ^ d[2] ^ d[3];
    assign p3 = d[1] ^ d[2] ^ d[3];
    
    // 组装汉明码
    assign hamming_out = {d[3], d[2], d[1], p3, d[0], p2, p1};
endmodule