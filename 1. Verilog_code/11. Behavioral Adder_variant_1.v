// 顶层模块
module behavioral_adder_top(
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum,
    output cout
);

    // 内部信号
    wire [8:0] full_sum;
    
    // 实例化加法器核心模块
    adder_core adder_inst (
        .a(a),
        .b(b),
        .full_sum(full_sum)
    );
    
    // 实例化输出处理模块
    output_handler out_handler (
        .full_sum(full_sum),
        .sum(sum),
        .cout(cout)
    );

endmodule

// 加法器核心模块
module adder_core(
    input [7:0] a,
    input [7:0] b,
    output [8:0] full_sum
);

    // 使用参数化位宽
    parameter WIDTH = 8;
    
    // 组合逻辑加法
    assign full_sum = {1'b0, a} + {1'b0, b};

endmodule

// 输出处理模块
module output_handler(
    input [8:0] full_sum,
    output reg [7:0] sum,
    output reg cout
);

    // 分离和寄存输出
    always @(*) begin
        sum = full_sum[7:0];
        cout = full_sum[8];
    end

endmodule