//SystemVerilog
module dual_output_decoder(
    input [2:0] binary_in,
    output [7:0] onehot_out,
    output [2:0] gray_out
);
    // 实例化一个热码转换器子模块
    binary_to_onehot_converter onehot_generator(
        .binary_in(binary_in),
        .onehot_out(onehot_out)
    );
    
    // 实例化格雷码转换器子模块
    binary_to_gray_converter gray_generator(
        .binary_in(binary_in),
        .gray_out(gray_out)
    );
endmodule

// 子模块：二进制到一个热码的转换器
module binary_to_onehot_converter(
    input [2:0] binary_in,
    output reg [7:0] onehot_out
);
    // 使用移位操作将二进制输入转换为一个热码输出
    always @(*) begin
        onehot_out = 8'h01 << binary_in;
    end
endmodule

// 子模块：二进制到格雷码的转换器
module binary_to_gray_converter(
    input [2:0] binary_in,
    output reg [2:0] gray_out
);
    // 优化的格雷码转换实现
    always @(*) begin
        // MSB保持不变
        gray_out[2] = binary_in[2];
        // 其他位是相邻二进制位的异或
        gray_out[1:0] = binary_in[2:1] ^ binary_in[1:0];
    end
endmodule