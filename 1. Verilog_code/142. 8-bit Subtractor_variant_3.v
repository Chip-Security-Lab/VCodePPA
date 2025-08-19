// 顶层模块
module subtractor_8bit (
    input wire [7:0] operand_a,  // 被减数
    input wire [7:0] operand_b,  // 减数
    output wire [7:0] result     // 差
);

    // 内部信号
    wire [7:0] inverted_b;       // 减数的补码
    wire [7:0] sum;              // 加法结果
    wire carry_out;              // 进位输出

    // 实例化补码转换模块
    complement_converter comp_conv (
        .input_data(operand_b),
        .output_data(inverted_b)
    );

    // 实例化加法器模块
    adder_8bit adder (
        .operand_a(operand_a),
        .operand_b(inverted_b),
        .carry_in(1'b1),         // 加1完成补码转换
        .sum(sum),
        .carry_out(carry_out)
    );

    // 实例化结果处理模块
    result_processor result_proc (
        .sum(sum),
        .carry_out(carry_out),
        .result(result)
    );

endmodule

// 补码转换模块
module complement_converter (
    input wire [7:0] input_data,
    output wire [7:0] output_data
);

    // 按位取反
    assign output_data = ~input_data;

endmodule

// 8位加法器模块
module adder_8bit (
    input wire [7:0] operand_a,
    input wire [7:0] operand_b,
    input wire carry_in,
    output wire [7:0] sum,
    output wire carry_out
);

    // 内部进位信号
    wire [8:0] carry;
    
    // 初始化进位
    assign carry[0] = carry_in;
    
    // 展开的加法器逻辑
    assign sum[0] = operand_a[0] ^ operand_b[0] ^ carry[0];
    assign carry[1] = (operand_a[0] & operand_b[0]) | 
                     (operand_a[0] & carry[0]) | 
                     (operand_b[0] & carry[0]);

    assign sum[1] = operand_a[1] ^ operand_b[1] ^ carry[1];
    assign carry[2] = (operand_a[1] & operand_b[1]) | 
                     (operand_a[1] & carry[1]) | 
                     (operand_b[1] & carry[1]);

    assign sum[2] = operand_a[2] ^ operand_b[2] ^ carry[2];
    assign carry[3] = (operand_a[2] & operand_b[2]) | 
                     (operand_a[2] & carry[2]) | 
                     (operand_b[2] & carry[2]);

    assign sum[3] = operand_a[3] ^ operand_b[3] ^ carry[3];
    assign carry[4] = (operand_a[3] & operand_b[3]) | 
                     (operand_a[3] & carry[3]) | 
                     (operand_b[3] & carry[3]);

    assign sum[4] = operand_a[4] ^ operand_b[4] ^ carry[4];
    assign carry[5] = (operand_a[4] & operand_b[4]) | 
                     (operand_a[4] & carry[4]) | 
                     (operand_b[4] & carry[4]);

    assign sum[5] = operand_a[5] ^ operand_b[5] ^ carry[5];
    assign carry[6] = (operand_a[5] & operand_b[5]) | 
                     (operand_a[5] & carry[5]) | 
                     (operand_b[5] & carry[5]);

    assign sum[6] = operand_a[6] ^ operand_b[6] ^ carry[6];
    assign carry[7] = (operand_a[6] & operand_b[6]) | 
                     (operand_a[6] & carry[6]) | 
                     (operand_b[6] & carry[6]);

    assign sum[7] = operand_a[7] ^ operand_b[7] ^ carry[7];
    assign carry[8] = (operand_a[7] & operand_b[7]) | 
                     (operand_a[7] & carry[7]) | 
                     (operand_b[7] & carry[7]);
    
    // 输出最终进位
    assign carry_out = carry[8];

endmodule

// 结果处理模块
module result_processor (
    input wire [7:0] sum,
    input wire carry_out,
    output wire [7:0] result
);

    // 直接输出和作为结果
    assign result = sum;

endmodule