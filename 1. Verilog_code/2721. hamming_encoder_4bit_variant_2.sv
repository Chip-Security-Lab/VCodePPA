//SystemVerilog
// 顶层模块 - 4位汉明编码器
module hamming_encoder_4bit(
    input clk, rst_n,
    input [3:0] data_in,
    output [6:0] encoded_out
);
    // 内部信号定义
    wire [2:0] parity_bits;
    wire [3:0] data_bits;
    
    // 实例化奇偶校验生成器子模块
    parity_generator parity_gen (
        .data_in(data_in),
        .parity_out(parity_bits)
    );
    
    // 实例化数据缓存子模块
    data_buffer data_buff (
        .data_in(data_in),
        .data_out(data_bits)
    );
    
    // 实例化输出寄存器子模块
    output_register out_reg (
        .clk(clk),
        .rst_n(rst_n),
        .parity_in(parity_bits),
        .data_in(data_bits),
        .encoded_out(encoded_out)
    );
endmodule

// 奇偶校验位生成子模块
module parity_generator(
    input [3:0] data_in,
    output [2:0] parity_out
);
    // 计算三个奇偶校验位
    assign parity_out[0] = data_in[0] ^ data_in[1] ^ data_in[3]; // 校验位P1
    assign parity_out[1] = data_in[0] ^ data_in[2] ^ data_in[3]; // 校验位P2
    assign parity_out[2] = data_in[1] ^ data_in[2] ^ data_in[3]; // 校验位P3
endmodule

// 数据缓存子模块
module data_buffer(
    input [3:0] data_in,
    output [3:0] data_out
);
    // 直接传递数据位
    assign data_out = data_in;
endmodule

// 输出寄存器子模块
module output_register(
    input clk, rst_n,
    input [2:0] parity_in,
    input [3:0] data_in,
    output reg [6:0] encoded_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_out <= 7'b0;
        end else begin
            // 按照汉明编码格式组装输出
            encoded_out[0] <= parity_in[0];  // P1
            encoded_out[1] <= parity_in[1];  // P2
            encoded_out[2] <= data_in[0];    // D1
            encoded_out[3] <= parity_in[2];  // P3
            encoded_out[4] <= data_in[1];    // D2
            encoded_out[5] <= data_in[2];    // D3
            encoded_out[6] <= data_in[3];    // D4
        end
    end
endmodule