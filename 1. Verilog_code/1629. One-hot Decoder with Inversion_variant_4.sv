//SystemVerilog
// 顶层模块
module invert_decoder #(
    parameter INVERT_OUTPUT = 0
)(
    input [2:0] bin_addr,
    output [7:0] dec_out
);
    wire [7:0] decoder_out;
    
    // 基本解码器子模块实例化
    basic_decoder u_basic_decoder (
        .bin_addr(bin_addr),
        .dec_out(decoder_out)
    );
    
    // 输出处理子模块实例化
    output_processor #(
        .INVERT_ENABLE(INVERT_OUTPUT)
    ) u_output_processor (
        .data_in(decoder_out),
        .data_out(dec_out)
    );
endmodule

// 基本解码器子模块 - 负责二进制到一热码的转换
module basic_decoder (
    input [2:0] bin_addr,
    output [7:0] dec_out
);
    // 使用多路复用器实现一热码生成
    wire [7:0] decoded [7:0];
    
    assign decoded[0] = 8'b00000001;
    assign decoded[1] = 8'b00000010;
    assign decoded[2] = 8'b00000100;
    assign decoded[3] = 8'b00001000;
    assign decoded[4] = 8'b00010000;
    assign decoded[5] = 8'b00100000;
    assign decoded[6] = 8'b01000000;
    assign decoded[7] = 8'b10000000;
    
    assign dec_out = decoded[bin_addr];
endmodule

// 输出处理子模块 - 负责可配置的输出信号处理
module output_processor #(
    parameter INVERT_ENABLE = 0
)(
    input [7:0] data_in,
    output [7:0] data_out
);
    // 使用多路复用器实现条件反转
    wire [7:0] inverted_data;
    wire [7:0] non_inverted_data;
    
    assign inverted_data = ~data_in;
    assign non_inverted_data = data_in;
    
    assign data_out = INVERT_ENABLE ? inverted_data : non_inverted_data;
endmodule