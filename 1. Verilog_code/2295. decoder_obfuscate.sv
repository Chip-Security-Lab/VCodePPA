module decoder_obfuscate #(parameter KEY=8'hA5) (
    input [7:0] cipher_addr,
    output [15:0] decoded
);
    wire [7:0] real_addr = cipher_addr ^ KEY;  // 简单异或解密
    assign decoded = (real_addr < 16) ? (1'b1 << real_addr) : 0;
endmodule