//SystemVerilog
module crc16_parallel #(parameter INIT = 16'hFFFF) (
    input clk, load_en,
    input [15:0] data_in,
    output reg [15:0] crc_reg
);
    // 声明Wallace树乘法器的内部信号
    wire [15:0] wallace_result;
    wire [7:0] mult_input = crc_reg[15:8] ^ data_in[15:8];
    
    // 实例化Wallace树乘法器
    wallace_multiplier wallace_mult_inst (
        .a(mult_input),
        .b(16'h1021),
        .product(wallace_result)
    );
    
    wire [15:0] next_crc = {crc_reg[7:0], 8'h00} ^ 
                         (mult_input == 8'h00) ? 16'h0000 :
                         (mult_input == 8'h01) ? 16'h1021 :
                         (mult_input == 8'h02) ? 16'h2042 :
                         (mult_input == 8'hFD) ? 16'hB8ED :
                         (mult_input == 8'hFE) ? 16'hA9CE :
                         (mult_input == 8'hFF) ? 16'h9ACF :
                         wallace_result;
    
    initial begin
        crc_reg = INIT;
    end
    
    always @(posedge clk) 
        if (load_en) crc_reg <= next_crc;
endmodule

// Wallace树乘法器实现
module wallace_multiplier (
    input [7:0] a,        // 8位乘数
    input [15:0] b,       // 16位乘数
    output [15:0] product // 16位乘积
);
    // 部分积生成
    wire [15:0] pp[7:0];
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: gen_partial_products
            assign pp[i] = a[i] ? (b << i) : 16'b0;
        end
    endgenerate
    
    // 第一级压缩
    wire [15:0] s1_1, c1_1, s1_2, c1_2;
    compressor_3_2 comp1_1(pp[0], pp[1], pp[2], s1_1, c1_1);
    compressor_3_2 comp1_2(pp[3], pp[4], pp[5], s1_2, c1_2);
    
    // 第二级压缩
    wire [15:0] s2_1, c2_1;
    compressor_3_2 comp2_1(s1_1, c1_1 << 1, s1_2, s2_1, c2_1);
    
    // 第三级压缩
    wire [15:0] s3_1, c3_1;
    compressor_3_2 comp3_1(s2_1, c2_1 << 1, c1_2 << 1, s3_1, c3_1);
    
    // 最终加法
    wire [15:0] sum1 = s3_1 + (c3_1 << 1) + pp[6] + pp[7];
    
    // 截断到16位
    assign product = sum1[15:0];
endmodule

// 3:2压缩器模块
module compressor_3_2 (
    input [15:0] a, b, c,
    output [15:0] sum, carry
);
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin: gen_comp
            assign sum[i] = a[i] ^ b[i] ^ c[i];
            assign carry[i] = (a[i] & b[i]) | (b[i] & c[i]) | (a[i] & c[i]);
        end
    endgenerate
endmodule