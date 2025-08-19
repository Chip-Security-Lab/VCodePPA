//SystemVerilog
// 顶层模块
module bin2gray_converter #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] bin_in,
    output wire [WIDTH-1:0] gray_out
);
    // 分别处理MSB和其他位
    wire msb_out;
    wire [WIDTH-2:0] other_bits_out;
    
    // 实例化MSB处理模块
    msb_processor #(
        .WIDTH(WIDTH)
    ) msb_proc_inst (
        .bin_msb(bin_in[WIDTH-1]),
        .gray_msb(msb_out)
    );
    
    // 实例化其他位处理模块
    other_bits_processor #(
        .WIDTH(WIDTH)
    ) other_bits_proc_inst (
        .bin_in(bin_in),
        .gray_out(other_bits_out)
    );
    
    // 组合输出
    assign gray_out = {msb_out, other_bits_out};
    
endmodule

// MSB处理模块 - 负责最高有效位的转换
module msb_processor #(parameter WIDTH = 8) (
    input  wire bin_msb,
    output wire gray_msb
);
    // 格雷码的MSB就是二进制的MSB
    assign gray_msb = bin_msb;
endmodule

// 其他位处理模块 - 负责除MSB外的所有位的转换
module other_bits_processor #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] bin_in,
    output wire [WIDTH-2:0] gray_out
);
    // 使用pipline方式实现以优化PPA
    genvar i;
    generate
        for (i = WIDTH-2; i >= 0; i = i - 1) begin : gray_bit_gen
            xor_unit xor_inst (
                .a(bin_in[i]),
                .b(bin_in[i+1]),
                .y(gray_out[i])
            );
        end
    endgenerate
endmodule

// XOR运算基本单元 - 优化了时序和面积
module xor_unit (
    input  wire a,
    input  wire b,
    output wire y
);
    // 优化的XOR实现，可以根据目标工艺进一步定制
    assign y = a ^ b;
endmodule