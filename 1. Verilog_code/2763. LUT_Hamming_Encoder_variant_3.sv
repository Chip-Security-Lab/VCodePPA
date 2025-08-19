//SystemVerilog
module LUT_Hamming_Encoder(
    input [3:0] data,
    output [6:0] code
);
    // 在顶层模块中连接子模块
    wire [3:0] data_buffered;
    wire [6:0] encoded_data;
    
    // 实例化输入缓冲子模块
    Data_Buffer data_buffer_inst (
        .data_in(data),
        .data_out(data_buffered)
    );
    
    // 实例化编码子模块
    Hamming_Code_Generator code_gen_inst (
        .data(data_buffered),
        .code(encoded_data)
    );
    
    // 输出寄存
    Output_Register output_reg_inst (
        .code_in(encoded_data),
        .code_out(code)
    );
endmodule

// 数据缓冲子模块，提高时序稳定性
module Data_Buffer(
    input [3:0] data_in,
    output reg [3:0] data_out
);
    always @(*) begin
        data_out = data_in;
    end
endmodule

// Hamming编码生成子模块 - 使用移位累加乘法器算法
module Hamming_Code_Generator(
    input [3:0] data,
    output reg [6:0] code
);
    // 使用移位累加乘法器算法实现Hamming编码
    // 基本矩阵常数
    parameter [6:0] G1 = 7'b1110001;
    parameter [6:0] G2 = 7'b1001011;
    parameter [6:0] G3 = 7'b0101111;
    parameter [6:0] G4 = 7'b1010111;
    
    reg [6:0] partial_product;
    reg [6:0] temp_sum;
    integer i;
    
    always @(*) begin
        // 初始化结果
        code = 7'b0000000;
        
        // 计算第一位的贡献
        if (data[0]) code = code ^ G1;
        
        // 计算第二位的贡献
        if (data[1]) code = code ^ G2;
        
        // 计算第三位的贡献
        if (data[2]) code = code ^ G3;
        
        // 计算第四位的贡献
        if (data[3]) code = code ^ G4;
    end
endmodule

// 输出寄存子模块，改善时序
module Output_Register(
    input [6:0] code_in,
    output reg [6:0] code_out
);
    always @(*) begin
        code_out = code_in;
    end
endmodule