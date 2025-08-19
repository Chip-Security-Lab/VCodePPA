//SystemVerilog
// 顶层模块 - 差分滤波器
module async_diff_filter #(
    parameter DATA_SIZE = 10
)(
    input [DATA_SIZE-1:0] current_sample,
    input [DATA_SIZE-1:0] prev_sample,
    output [DATA_SIZE:0] diff_out  // One bit wider to handle negative
);
    // 内部连线
    wire [DATA_SIZE:0] extended_current;
    wire [DATA_SIZE:0] extended_prev;
    
    // 信号处理单元 - 同时处理两个样本的扩展
    signal_processor #(
        .DATA_SIZE(DATA_SIZE)
    ) sig_proc (
        .current_in(current_sample),
        .prev_in(prev_sample),
        .current_ext(extended_current),
        .prev_ext(extended_prev)
    );
    
    // 差分计算单元
    diff_calculator #(
        .WIDTH(DATA_SIZE+1)
    ) diff_calc (
        .minuend(extended_current),
        .subtrahend(extended_prev),
        .result(diff_out)
    );
endmodule

// 信号处理单元 - 集成两个样本的符号扩展
module signal_processor #(
    parameter DATA_SIZE = 10
)(
    input [DATA_SIZE-1:0] current_in,
    input [DATA_SIZE-1:0] prev_in,
    output [DATA_SIZE:0] current_ext,
    output [DATA_SIZE:0] prev_ext
);
    // 批量处理符号扩展，减少资源占用
    sign_extend_unit #(
        .DATA_SIZE(DATA_SIZE)
    ) current_extender (
        .data_in(current_in),
        .data_out(current_ext)
    );
    
    sign_extend_unit #(
        .DATA_SIZE(DATA_SIZE)
    ) prev_extender (
        .data_in(prev_in),
        .data_out(prev_ext)
    );
endmodule

// 优化的符号位扩展单元
module sign_extend_unit #(
    parameter DATA_SIZE = 10
)(
    input [DATA_SIZE-1:0] data_in,
    output [DATA_SIZE:0] data_out
);
    // 扩展一位符号位，优化逻辑层次
    assign data_out = {{1{data_in[DATA_SIZE-1]}}, data_in};
endmodule

// 使用条件求和算法优化的差分计算单元
module diff_calculator #(
    parameter WIDTH = 11
)(
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] result
);
    // 条件求和减法算法实现
    wire [WIDTH-1:0] inverted_subtrahend;
    wire [WIDTH-1:0] conditional_sum;
    wire carry_in;
    
    // 对减数取反
    assign inverted_subtrahend = ~subtrahend;
    // 减法转化为加法，加1实现补码
    assign carry_in = 1'b1;
    
    // 条件求和减法实现
    conditional_sum_adder #(
        .WIDTH(WIDTH)
    ) cond_sum_adder (
        .a(minuend),
        .b(inverted_subtrahend),
        .cin(carry_in),
        .sum(result)
    );
endmodule

// 条件求和加法器模块
module conditional_sum_adder #(
    parameter WIDTH = 11
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum
);
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] sum0, sum1;
    
    assign carry[0] = cin;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_sum
            // 预计算两种情况下的和
            assign sum0[i] = a[i] ^ b[i];
            assign sum1[i] = a[i] ^ b[i] ^ 1'b1;
            
            // 根据进位选择正确的和
            assign sum[i] = carry[i] ? sum1[i] : sum0[i];
            
            // 计算下一位的进位
            assign carry[i+1] = carry[i] ? 
                                (a[i] | b[i]) : 
                                (a[i] & b[i]);
        end
    endgenerate
endmodule