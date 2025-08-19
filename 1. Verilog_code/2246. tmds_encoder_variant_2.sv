//SystemVerilog
// Top level module
module tmds_encoder (
    input  wire       clk,         // 添加时钟信号以支持流水线
    input  wire       rst_n,       // 添加复位信号
    input  wire [7:0] pixel_data,  // 像素数据输入
    input  wire       hsync,       // 水平同步信号
    input  wire       vsync,       // 垂直同步信号
    input  wire       active,      // 有效显示区域标志
    output reg  [9:0] encoded      // 编码后的输出
);
    // 定义流水线级信号
    reg [7:0] pixel_data_r1;
    reg       hsync_r1, vsync_r1, active_r1;
    reg [3:0] ones_count_r1;
    
    // 用于1的计数的信号
    wire [3:0] ones_count;
    
    // 流水线第一级：寄存像素数据和控制信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_data_r1 <= 8'h0;
            hsync_r1 <= 1'b0;
            vsync_r1 <= 1'b0;
            active_r1 <= 1'b0;
            ones_count_r1 <= 4'h0;
        end else begin
            pixel_data_r1 <= pixel_data;
            hsync_r1 <= hsync;
            vsync_r1 <= vsync;
            active_r1 <= active;
            ones_count_r1 <= ones_count;
        end
    end
    
    // 使用优化的计数器计算1的个数
    bit_counter u_popcount (
        .data(pixel_data),
        .count(ones_count)
    );
    
    // 流水线第二级：TMDS编码逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded <= 10'h0;
        end else begin
            // TMDS编码决策逻辑
            case({active_r1, (ones_count_r1 > 4'd4 || (ones_count_r1 == 4'd4 && !pixel_data_r1[0]))})
                2'b11: encoded <= {~pixel_data_r1[7], pixel_data_r1[6:0] ^ {7{pixel_data_r1[7]}}};
                2'b10: encoded <= {2'b01, hsync_r1, vsync_r1, 6'b000000};
                default: encoded <= 10'b1101010100; // 控制码
            endcase
        end
    end
endmodule

// 优化的位计数器 - 使用CSA (Carry Save Adder) 树结构
module bit_counter (
    input  wire [7:0] data,
    output wire [3:0] count
);
    // 第一级压缩: 使用3:2 压缩器
    wire [2:0] level1_sum1;    // 前3位压缩结果
    wire [2:0] level1_sum2;    // 中间3位压缩结果
    wire [1:0] level1_sum3;    // 后2位压缩结果
    
    // 第一级压缩单元 - 将8位分为3组
    csa_3_2 csa1_1 (
        .in1(data[0]),
        .in2(data[1]),
        .in3(data[2]),
        .sum(level1_sum1[0]),
        .carry(level1_sum1[1])
    );
    
    csa_3_2 csa1_2 (
        .in1(data[3]),
        .in2(data[4]),
        .in3(data[5]),
        .sum(level1_sum2[0]),
        .carry(level1_sum2[1])
    );
    
    // 使用半加器处理剩余的2位
    half_adder ha1 (
        .a(data[6]),
        .b(data[7]),
        .sum(level1_sum3[0]),
        .cout(level1_sum3[1])
    );
    
    // 为第二级准备数据
    assign level1_sum1[2] = 1'b0;  // 扩展为3位
    assign level1_sum2[2] = 1'b0;  // 扩展为3位
    
    // 第二级压缩: 合并第一级的结果
    wire [3:0] level2_sum1;
    wire [3:0] level2_sum2;
    
    // 合并第一级的前两组结果
    csa_vector_4bit csa2_1 (
        .a({1'b0, level1_sum1}),
        .b({1'b0, level1_sum2}),
        .sum(level2_sum1)
    );
    
    // 准备第三级输入
    assign level2_sum2 = {2'b00, level1_sum3};
    
    // 第三级: 最终的加法
    csa_vector_4bit_final csa3 (
        .a(level2_sum1),
        .b(level2_sum2),
        .sum(count)
    );
endmodule

// 3:2 压缩器 (全加器)
module csa_3_2 (
    input  wire in1, in2, in3,
    output wire sum, carry
);
    assign sum = in1 ^ in2 ^ in3;
    assign carry = (in1 & in2) | (in2 & in3) | (in1 & in3);
endmodule

// 半加器模块
module half_adder (
    input  wire a, b,
    output wire sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

// 4位向量 CSA 加法器
module csa_vector_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] sum
);
    wire [3:0] carries;
    
    // 级联的CSA结构
    half_adder ha_0 (
        .a(a[0]),
        .b(b[0]),
        .sum(sum[0]),
        .cout(carries[0])
    );
    
    full_adder fa_1 (
        .a(a[1]),
        .b(b[1]),
        .cin(carries[0]),
        .sum(sum[1]),
        .cout(carries[1])
    );
    
    full_adder fa_2 (
        .a(a[2]),
        .b(b[2]),
        .cin(carries[1]),
        .sum(sum[2]),
        .cout(carries[2])
    );
    
    full_adder fa_3 (
        .a(a[3]),
        .b(b[3]),
        .cin(carries[2]),
        .sum(sum[3]),
        .cout(carries[3])
    );
endmodule

// 最终4位向量加法器
module csa_vector_4bit_final (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] sum
);
    wire [4:0] temp_sum;  // 额外一位用于最高位进位
    
    // 使用简单的加法器实现最终结果
    assign temp_sum = a + b;
    assign sum = temp_sum[3:0];  // 截断可能的溢出位
endmodule

// 全加器模块
module full_adder (
    input  wire a, b, cin,
    output wire sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule