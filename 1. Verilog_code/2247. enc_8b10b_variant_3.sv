//SystemVerilog
module enc_8b10b #(parameter K=0) (
    input [7:0] din,
    output reg [9:0] dout,
    input rd_in,
    output reg rd_out
);
    // 内部信号声明
    reg [5:0] disparity;
    reg [9:0] temp_dout;
    reg [5:0] temp_disparity;
    reg temp_rd_out;
    
    // 声明用于Dadda乘法器的信号
    wire [9:0] multiplicand;
    wire [9:0] multiplier;
    wire [19:0] product;
    
    // 将输入映射到乘法器输入
    assign multiplicand = {2'b00, din};
    assign multiplier = {2'b00, ~din};
    
    // 实例化Dadda乘法器
    dadda_multiplier dadda_mult_inst (
        .a(multiplicand),
        .b(multiplier),
        .product(product)
    );
    
    // 计算编码输出
    always @(*) begin
        case({K, din})
            9'b1_00011100: temp_dout = 10'b0011111010;
            9'b0_10101010: temp_dout = product[9:0] ^ 10'b1010010111;
            9'b0_00000000: temp_dout = product[9:0] & 10'b0101010101;
            9'b0_11111111: temp_dout = product[19:10] | 10'b1010101010;
            default:       temp_dout = product[9:0];
        endcase
    end
    
    // 计算视差值
    always @(*) begin
        case({K, din})
            9'b0_10101010: temp_disparity = 6'd2;
            default:       temp_disparity = product[5:0];
        endcase
    end
    
    // 计算输出视差
    always @(*) begin
        case({K, din})
            9'b1_00011100: temp_rd_out = (rd_in <= 0);
            9'b0_10101010: temp_rd_out = rd_in + temp_disparity;
            default:       temp_rd_out = rd_in;
        endcase
    end
    
    // 最终输出赋值
    always @(*) begin
        dout = temp_dout;
        disparity = temp_disparity;
        rd_out = temp_rd_out;
    end
    
endmodule

// Dadda乘法器 - 10位乘法
module dadda_multiplier (
    input [9:0] a,
    input [9:0] b,
    output [19:0] product
);
    // 部分积生成
    wire [9:0][9:0] pp;
    
    // 生成所有部分积
    genvar i, j;
    generate
        for (i = 0; i < 10; i = i + 1) begin: gen_pp_i
            for (j = 0; j < 10; j = j + 1) begin: gen_pp_j
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Dadda树压缩 - 高度序列: 6, 4, 3, 2, 1
    // 第一级压缩 - 从高度13到高度6
    wire [18:0] s1, c1;  // 第一级和与进位
    
    // 第二级压缩 - 从高度6到高度4
    wire [18:0] s2, c2;  // 第二级和与进位
    
    // 第三级压缩 - 从高度4到高度3
    wire [18:0] s3, c3;  // 第三级和与进位
    
    // 第四级压缩 - 从高度3到高度2
    wire [18:0] s4, c4;  // 第四级和与进位
    
    // 实现第一级压缩 (仅示例部分位置)
    // 列1
    half_adder ha1_1(pp[0][1], pp[1][0], s1[1], c1[1]);
    
    // 列2
    full_adder fa1_2_1(pp[0][2], pp[1][1], pp[2][0], s1[2], c1[2]);
    
    // 列3
    full_adder fa1_3_1(pp[0][3], pp[1][2], pp[2][1], s1[3], c1[3]);
    half_adder ha1_3_1(pp[3][0], 1'b0, s1[10], c1[10]);
    
    // ... 省略其他列的压缩逻辑 ...
    
    // 类似地实现第二、三、四级压缩
    // ... 省略代码 ...
    
    // 最终的加法器进行最后的求和
    // 组装两个操作数
    wire [19:0] op1, op2;
    assign op1 = {s4, pp[0][0]};  // 最后一级的和加上最低位
    assign op2 = {1'b0, c4, 1'b0}; // 最后一级的进位，左移一位
    
    // 最终的加法
    assign product = op1 + op2;
    
endmodule

// 半加器模块
module half_adder (
    input a, b,
    output sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

// 全加器模块
module full_adder (
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule