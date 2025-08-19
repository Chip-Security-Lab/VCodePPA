// 补码转换子模块 - 将输入数据转换为补码
module complement_converter (
    input wire [3:0] input_data,
    output wire [3:0] complement
);
    assign complement = ~input_data + 1'b1;
endmodule

// 加法器子模块 - 执行4位加法运算
module adder_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [4:0] sum
);
    assign sum = {1'b0, a} + {1'b0, b};
endmodule

// 结果选择子模块 - 从带进位的和中提取结果
module result_selector (
    input wire [4:0] sum_with_carry,
    output wire [3:0] result
);
    assign result = sum_with_carry[3:0];
endmodule

// 顶层减法器模块 - 通过补码加法实现减法
module subtractor_4bit (
    input wire [3:0] a,    // 被减数
    input wire [3:0] b,    // 减数
    output wire [3:0] res  // 差
);
    wire [3:0] b_comp;     // 减数的补码
    wire [4:0] sum_temp;   // 临时和，包含进位位
    
    // 实例化补码转换子模块
    complement_converter comp_conv (
        .input_data(b),
        .complement(b_comp)
    );
    
    // 实例化加法器子模块
    adder_4bit add (
        .a(a),
        .b(b_comp),
        .sum(sum_temp)
    );
    
    // 实例化结果选择子模块
    result_selector res_sel (
        .sum_with_carry(sum_temp),
        .result(res)
    );
endmodule