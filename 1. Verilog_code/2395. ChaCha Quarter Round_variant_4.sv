//SystemVerilog
module chacha_quarter_round (
    input wire [31:0] a_in, b_in, c_in, d_in,
    output wire [31:0] a_out, b_out, c_out, d_out
);
    // 优化的ChaCha20四分之一轮函数
    wire [31:0] a_temp, d_temp, c_temp, b_temp;
    
    // 合并加法运算，减少逻辑深度
    assign a_temp = a_in + b_in;
    assign d_temp = {(d_in[15:0] ^ a_temp[31:16]), (d_in[31:16] ^ a_temp[15:0])};
    
    // 优化旋转与异或操作
    assign c_temp = c_in + d_temp;
    assign b_temp = {(b_in[19:0] ^ c_temp[31:20]), (b_in[31:20] ^ c_temp[19:0])};
    
    // 直接输出
    assign a_out = a_temp + b_temp;
    assign b_out = b_temp;
    assign c_out = c_temp;
    assign d_out = d_temp;
endmodule