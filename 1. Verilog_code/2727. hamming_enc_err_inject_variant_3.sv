//SystemVerilog
module hamming_enc_err_inject(
    input clk, rst,
    input [3:0] data,
    input inject_error,
    input [2:0] error_pos,
    output [6:0] encoded
);
    wire [6:0] normal_encoded;
    wire [6:0] error_mask;
    
    // 预计算错误掩码
    assign error_mask = inject_error ? (7'b1 << error_pos) : 7'b0;
    
    // 合并编码和错误注入逻辑
    assign encoded = {
        data[3],                    // D4
        data[2],                    // D3
        data[1],                    // D2
        data[1] ^ data[2] ^ data[3], // P3
        data[0],                    // D1
        data[0] ^ data[2] ^ data[3], // P2
        data[0] ^ data[1] ^ data[3]  // P1
    } ^ error_mask;
endmodule