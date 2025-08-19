//SystemVerilog
module error_detect_demux (
    input wire data,                     // 输入数据
    input wire [2:0] address,            // 地址选择
    output reg [4:0] outputs,            // 输出线
    output reg error_flag,               // 错误指示
    
    // 乘法器接口
    input wire [4:0] multiplicand,       // 5位乘数
    input wire [4:0] multiplier,         // 5位被乘数
    output wire [9:0] product            // 10位乘积结果
);
    // 原始解复用功能
    always @(*) begin
        outputs = 5'b0;
        error_flag = 1'b0;
        
        if (address < 5) 
            outputs[address] = data;     // 有效路由
        else
            error_flag = data;           // 无效地址的错误指示
    end
    
    // 实例化dadda乘法器
    dadda_multiplier_5bit dadda_mult (
        .a(multiplicand),
        .b(multiplier),
        .p(product)
    );
endmodule

// dadda乘法器实现(5位宽)
module dadda_multiplier_5bit (
    input wire [4:0] a,      // 5位乘数
    input wire [4:0] b,      // 5位被乘数
    output wire [9:0] p      // 乘积结果
);
    // 部分积生成
    wire pp[4:0][4:0];       // 部分积矩阵
    
    // 生成所有部分积
    genvar i, j;
    generate
        for (i = 0; i < 5; i = i + 1) begin: gen_pp_i
            for (j = 0; j < 5; j = j + 1) begin: gen_pp_j
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Dadda压缩阶段
    // 第一级: 从25个部分积压缩到13个(Dadda数: 2,3,4,6,9,13,19,...)
    wire [0:0] s1_0, c1_0;  // 全加器1的输出
    wire [0:0] s1_1, c1_1;  // 全加器2的输出
    wire [0:0] s1_2, c1_2;  // 全加器3的输出
    wire [0:0] s1_3, c1_3;  // 全加器4的输出
    
    // 第一级全加器
    full_adder fa1_0 (.a(pp[0][4]), .b(pp[1][3]), .cin(pp[2][2]), .sum(s1_0), .cout(c1_0));
    full_adder fa1_1 (.a(pp[3][1]), .b(pp[4][0]), .cin(1'b0),     .sum(s1_1), .cout(c1_1));
    full_adder fa1_2 (.a(pp[1][4]), .b(pp[2][3]), .cin(pp[3][2]), .sum(s1_2), .cout(c1_2));
    full_adder fa1_3 (.a(pp[4][1]), .b(1'b0),     .cin(1'b0),     .sum(s1_3), .cout(c1_3));
    
    // 半加器
    wire [0:0] s1_4, c1_4;
    wire [0:0] s1_5, c1_5;
    half_adder ha1_0 (.a(pp[0][3]), .b(pp[1][2]), .sum(s1_4), .cout(c1_4));
    half_adder ha1_1 (.a(pp[2][4]), .b(pp[3][3]), .sum(s1_5), .cout(c1_5));
    
    // 第二级: 从13个压缩到9个
    wire [0:0] s2_0, c2_0;
    wire [0:0] s2_1, c2_1;
    wire [0:0] s2_2, c2_2;
    
    full_adder fa2_0 (.a(s1_0), .b(s1_1), .cin(c1_4), .sum(s2_0), .cout(c2_0));
    full_adder fa2_1 (.a(s1_2), .b(s1_3), .cin(c1_0), .sum(s2_1), .cout(c2_1));
    full_adder fa2_2 (.a(s1_5), .b(pp[4][2]), .cin(c1_1), .sum(s2_2), .cout(c2_2));
    
    // 半加器
    wire [0:0] s2_3, c2_3;
    half_adder ha2_0 (.a(c1_2), .b(c1_5), .sum(s2_3), .cout(c2_3));
    
    // 第三级: 从9个压缩到6个
    wire [0:0] s3_0, c3_0;
    wire [0:0] s3_1, c3_1;
    
    full_adder fa3_0 (.a(s2_0), .b(s2_1), .cin(pp[2][1]), .sum(s3_0), .cout(c3_0));
    full_adder fa3_1 (.a(s2_2), .b(s2_3), .cin(c2_0), .sum(s3_1), .cout(c3_1));
    
    // 构建最终加法的两个操作数
    wire [9:0] term1, term2;
    
    assign term1[0] = pp[0][0];
    assign term1[1] = pp[0][1];
    assign term1[2] = s1_4;
    assign term1[3] = s3_0;
    assign term1[4] = s3_1;
    assign term1[5] = pp[3][4];
    assign term1[6] = pp[4][3];
    assign term1[7] = pp[4][4];
    assign term1[8] = 1'b0;
    assign term1[9] = 1'b0;
    
    assign term2[0] = 1'b0;
    assign term2[1] = pp[1][0];
    assign term2[2] = pp[1][1];
    assign term2[3] = c3_0;
    assign term2[4] = c3_1;
    assign term2[5] = c2_1;
    assign term2[6] = c2_2;
    assign term2[7] = c2_3;
    assign term2[8] = 1'b0;
    assign term2[9] = 1'b0;
    
    // 使用Han-Carlson加法器替代简单加法器
    han_carlson_adder #(.WIDTH(10)) final_adder (
        .a(term1),
        .b(term2),
        .sum(p)
    );
endmodule

// 全加器模块
module full_adder (
    input wire a, b, cin,
    output wire sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// 半加器模块
module half_adder (
    input wire a, b,
    output wire sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

// Han-Carlson并行前缀加法器模块
module han_carlson_adder #(
    parameter WIDTH = 10
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] sum
);
    // 第一阶段：预处理，生成传播和生成信号
    wire [WIDTH-1:0] p, g;
    genvar i;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_pg
            assign p[i] = a[i] ^ b[i]; // 传播信号
            assign g[i] = a[i] & b[i]; // 生成信号
        end
    endgenerate
    
    // 定义内部节点 - Han-Carlson算法仅在偶数位上计算前缀
    wire [WIDTH-1:0] pp[0:$clog2(WIDTH)];
    wire [WIDTH-1:0] gg[0:$clog2(WIDTH)];
    
    // 初始化第0级
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: init_pg
            assign pp[0][i] = p[i];
            assign gg[0][i] = g[i];
        end
    endgenerate
    
    // Han-Carlson树 - 仅计算偶数索引位置
    wire [WIDTH-1:0] even_pp[0:$clog2(WIDTH)];
    wire [WIDTH-1:0] even_gg[0:$clog2(WIDTH)];
    wire [WIDTH-1:0] odd_pp[0:$clog2(WIDTH)];
    wire [WIDTH-1:0] odd_gg[0:$clog2(WIDTH)];
    
    // 初始化偶数和奇数位
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: init_even_odd
            if (i % 2 == 0) begin
                assign even_pp[0][i] = pp[0][i];
                assign even_gg[0][i] = gg[0][i];
            end else begin
                assign odd_pp[0][i] = pp[0][i];
                assign odd_gg[0][i] = gg[0][i];
            end
        end
    endgenerate
    
    // 前缀计算阶段
    generate
        genvar j, k;
        // 计算每一级的偶数位
        for (j = 1; j <= $clog2(WIDTH); j = j + 1) begin: prefix_levels
            for (k = 0; k < WIDTH; k = k + 1) begin: prefix_ops
                if (k % 2 == 0) begin // 只处理偶数位
                    if (k >= (2**j)) begin
                        // 应用前缀运算
                        assign even_pp[j][k] = even_pp[j-1][k] & even_pp[j-1][k-(2**(j-1))];
                        assign even_gg[j][k] = even_gg[j-1][k] | (even_pp[j-1][k] & even_gg[j-1][k-(2**(j-1))]);
                    end else begin
                        // 保持不变
                        assign even_pp[j][k] = even_pp[j-1][k];
                        assign even_gg[j][k] = even_gg[j-1][k];
                    end
                end
            end
        end
        
        // 计算奇数位 - 它们向前偶数位借位
        for (k = 0; k < WIDTH; k = k + 1) begin: odd_prefix_ops
            if (k % 2 != 0 && k > 0) begin // 奇数位，除了位置0
                assign odd_pp[$clog2(WIDTH)][k] = pp[0][k] & even_pp[$clog2(WIDTH)][k-1];
                assign odd_gg[$clog2(WIDTH)][k] = gg[0][k] | (pp[0][k] & even_gg[$clog2(WIDTH)][k-1]);
            end
        end
    endgenerate
    
    // 后处理阶段：计算最终进位和和
    wire [WIDTH:0] carry;
    assign carry[0] = 1'b0; // 初始进位为0
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_sum
            if (i % 2 == 0) begin // 偶数位
                assign carry[i+1] = even_gg[$clog2(WIDTH)][i];
            end else begin // 奇数位
                assign carry[i+1] = odd_gg[$clog2(WIDTH)][i];
            end
            assign sum[i] = p[i] ^ carry[i]; // 最终和
        end
    endgenerate
endmodule