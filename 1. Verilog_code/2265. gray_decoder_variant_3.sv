//SystemVerilog
// 顶层模块：格雷码解码器
module gray_decoder #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] gray_in,
    output [WIDTH-1:0] binary_out
);
    // 内部信号定义
    wire [WIDTH-1:0] binary_out_wire;
    
    // 实例化位解码模块
    bit_decoder #(
        .WIDTH(WIDTH)
    ) bit_decoder_inst (
        .gray_in(gray_in),
        .binary_out(binary_out_wire)
    );
    
    // 输出赋值
    assign binary_out = binary_out_wire;
    
endmodule

// 子模块：逐位解码器
module bit_decoder #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] gray_in,
    output [WIDTH-1:0] binary_out
);
    // 组合逻辑实现 - 使用归约异或操作，改善关键路径
    genvar i;
    generate
        // 最高位保持不变
        assign binary_out[WIDTH-1] = gray_in[WIDTH-1];
        
        // 其余位通过异或运算生成
        for (i = WIDTH-2; i >= 0; i = i - 1) begin : decode_bits
            assign binary_out[i] = binary_out[i+1] ^ gray_in[i];
        end
    endgenerate
    
endmodule