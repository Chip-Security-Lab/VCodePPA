//SystemVerilog
// 顶层模块：组织除法操作的整体流程
module divider_iterative_32bit (
    input [31:0] dividend,
    input [31:0] divisor,
    output [31:0] quotient,
    output [31:0] remainder
);

    wire [31:0] internal_remainder [32:0];
    wire [31:0] internal_quotient [32:0];
    
    // 初始化输入值
    assign internal_remainder[0] = dividend;
    assign internal_quotient[0] = 32'b0;
    
    // 实例化32个单次迭代子模块
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : div_stage
            divider_stage div_stage_inst (
                .current_remainder(internal_remainder[i]),
                .current_quotient(internal_quotient[i]),
                .divisor(divisor),
                .next_remainder(internal_remainder[i+1]),
                .next_quotient(internal_quotient[i+1])
            );
        end
    endgenerate
    
    // 输出最终结果
    assign quotient = internal_quotient[32];
    assign remainder = internal_remainder[32];
    
endmodule

// 单次迭代子模块：执行单次除法迭代
module divider_stage (
    input [31:0] current_remainder,
    input [31:0] current_quotient,
    input [31:0] divisor,
    output [31:0] next_remainder,
    output [31:0] next_quotient
);

    wire comparison_result;
    wire [31:0] subtraction_result;
    
    // 比较器子模块
    comparator comp_inst (
        .a(current_remainder),
        .b(divisor),
        .greater_equal(comparison_result)
    );
    
    // 减法器子模块使用带状进位加法器实现
    subtractor sub_inst (
        .a(current_remainder),
        .b(divisor),
        .enable(comparison_result),
        .result(subtraction_result)
    );
    
    // 商更新子模块
    quotient_updater qu_inst (
        .current_quotient(current_quotient),
        .comparison_result(comparison_result),
        .next_quotient(next_quotient)
    );
    
    // 计算下一个余数
    assign next_remainder = comparison_result ? subtraction_result : current_remainder;
    
endmodule

// 比较器子模块：比较当前余数和除数
module comparator (
    input [31:0] a,
    input [31:0] b,
    output greater_equal
);
    
    assign greater_equal = (a >= b) ? 1'b1 : 1'b0;
    
endmodule

// 减法器子模块：使用带状进位加法器实现减法
module subtractor (
    input [31:0] a,
    input [31:0] b,
    input enable,
    output [31:0] result
);
    
    wire [32:0] inverted_b;
    wire [32:0] a_extended;
    wire [32:0] sum;
    
    // 扩展a以匹配带状进位加法器的33位宽度
    assign a_extended = {1'b0, a};
    
    // 当启用时，计算b的二进制补码 (取反加一)
    assign inverted_b = enable ? {1'b0, ~b} + 33'b1 : {1'b0, a};
    
    // 实例化带状进位加法器
    carry_skip_adder_33bit csa (
        .a(a_extended),
        .b(inverted_b),
        .sum(sum)
    );
    
    // 结果是33位加法器的低32位
    assign result = enable ? sum[31:0] : a;
    
endmodule

// 带状进位加法器实现 (33位)
module carry_skip_adder_33bit (
    input [32:0] a,
    input [32:0] b,
    output [32:0] sum
);
    
    // 分组大小
    parameter GROUP_SIZE = 4;
    parameter NUM_GROUPS = 9; // 33位需要9个组，最后一个组只有1位
    
    wire [NUM_GROUPS:0] group_carry;
    wire [32:0] internal_sum;
    wire [NUM_GROUPS-1:0] group_propagate;
    
    // 初始进位为0
    assign group_carry[0] = 1'b0;
    
    // 生成各个组
    genvar g;
    generate
        for (g = 0; g < NUM_GROUPS-1; g = g + 1) begin : csa_groups
            wire [GROUP_SIZE-1:0] p; // 位传播信号
            wire [GROUP_SIZE-1:0] group_sum;
            wire group_cin, group_cout;
            
            // 组的输入进位
            assign group_cin = group_carry[g];
            
            // 实现一个组的加法
            carry_ripple_group #(
                .SIZE(GROUP_SIZE)
            ) ripple_group (
                .a(a[g*GROUP_SIZE +: GROUP_SIZE]),
                .b(b[g*GROUP_SIZE +: GROUP_SIZE]),
                .cin(group_cin),
                .sum(group_sum),
                .cout(group_cout),
                .p(p)
            );
            
            // 存储该组的和
            assign internal_sum[g*GROUP_SIZE +: GROUP_SIZE] = group_sum;
            
            // 计算组传播信号
            assign group_propagate[g] = &p;
            
            // 实现带状进位结构
            assign group_carry[g+1] = group_propagate[g] ? group_cin : group_cout;
        end
        
        // 最后一个组 (只有1位)
        begin : last_group
            wire p;
            wire group_cin, group_cout;
            wire last_sum;
            
            // 组的输入进位
            assign group_cin = group_carry[NUM_GROUPS-1];
            
            // 最后一个组的计算（只有1位）
            assign p = a[32] ^ b[32];
            assign last_sum = a[32] ^ b[32] ^ group_cin;
            assign group_cout = (a[32] & b[32]) | (p & group_cin);
            
            // 存储最后一位的和
            assign internal_sum[32] = last_sum;
            
            // 设置最后一个组的传播信号
            assign group_propagate[NUM_GROUPS-1] = p;
            
            // 最后一个组的输出进位 (虽然不使用)
            assign group_carry[NUM_GROUPS] = group_cout;
        end
    endgenerate
    
    // 最终输出
    assign sum = internal_sum;
    
endmodule

// 行波进位加法器组
module carry_ripple_group #(
    parameter SIZE = 4
)(
    input [SIZE-1:0] a,
    input [SIZE-1:0] b,
    input cin,
    output [SIZE-1:0] sum,
    output cout,
    output [SIZE-1:0] p
);
    
    wire [SIZE:0] carry;
    
    // 初始进位
    assign carry[0] = cin;
    
    // 计算每一位
    genvar i;
    generate
        for (i = 0; i < SIZE; i = i + 1) begin : ripple_bits
            // 计算传播信号
            assign p[i] = a[i] ^ b[i];
            
            // 计算每一位的和
            assign sum[i] = a[i] ^ b[i] ^ carry[i];
            
            // 计算进位
            assign carry[i+1] = (a[i] & b[i]) | (p[i] & carry[i]);
        end
    endgenerate
    
    // 输出进位
    assign cout = carry[SIZE];
    
endmodule

// 商更新子模块：根据比较结果更新商
module quotient_updater (
    input [31:0] current_quotient,
    input comparison_result,
    output [31:0] next_quotient
);
    
    assign next_quotient = comparison_result ? (current_quotient + 1'b1) : current_quotient;
    
endmodule