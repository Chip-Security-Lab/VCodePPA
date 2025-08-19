//SystemVerilog
// 顶层模块
module async_iir_filter #(
    parameter DW = 14
)(
    input [DW-1:0] x_in,
    input [DW-1:0] y_prev,
    input [DW-1:0] a_coeff, b_coeff,
    output [DW-1:0] y_out
);
    // 内部连线
    wire [DW-1:0] scaled_input, scaled_feedback;
    
    // 子模块实例化
    input_scaling #(
        .DATA_WIDTH(DW)
    ) u_input_scaling (
        .x_in(x_in),
        .a_coeff(a_coeff),
        .scaled_x(scaled_input)
    );
    
    feedback_scaling #(
        .DATA_WIDTH(DW)
    ) u_feedback_scaling (
        .y_prev(y_prev),
        .b_coeff(b_coeff),
        .scaled_y(scaled_feedback)
    );
    
    output_summation #(
        .DATA_WIDTH(DW)
    ) u_output_summation (
        .scaled_input(scaled_input),
        .scaled_feedback(scaled_feedback),
        .y_out(y_out)
    );
    
endmodule

// 输入信号缩放子模块
module input_scaling #(
    parameter DATA_WIDTH = 14
)(
    input [DATA_WIDTH-1:0] x_in,
    input [DATA_WIDTH-1:0] a_coeff,
    output [DATA_WIDTH-1:0] scaled_x
);
    // 乘法运算并提取合适的位
    wire [2*DATA_WIDTH-1:0] product;
    
    // 使用专用乘法器减少延迟
    mult_unit #(
        .WIDTH(DATA_WIDTH)
    ) u_mult (
        .a(x_in),
        .b(a_coeff),
        .product(product)
    );
    
    // 取高位作为结果
    assign scaled_x = product[2*DATA_WIDTH-1:DATA_WIDTH];
    
endmodule

// 反馈信号缩放子模块
module feedback_scaling #(
    parameter DATA_WIDTH = 14
)(
    input [DATA_WIDTH-1:0] y_prev,
    input [DATA_WIDTH-1:0] b_coeff,
    output [DATA_WIDTH-1:0] scaled_y
);
    // 乘法运算并提取合适的位
    wire [2*DATA_WIDTH-1:0] product;
    
    // 使用专用乘法器减少延迟
    mult_unit #(
        .WIDTH(DATA_WIDTH)
    ) u_mult (
        .a(y_prev),
        .b(b_coeff),
        .product(product)
    );
    
    // 取高位作为结果
    assign scaled_y = product[2*DATA_WIDTH-1:DATA_WIDTH];
    
endmodule

// 输出求和子模块
module output_summation #(
    parameter DATA_WIDTH = 14
)(
    input [DATA_WIDTH-1:0] scaled_input,
    input [DATA_WIDTH-1:0] scaled_feedback,
    output [DATA_WIDTH-1:0] y_out
);
    // 简单求和操作
    assign y_out = scaled_input + scaled_feedback;
    
endmodule

// 通用乘法器单元，可针对不同技术进行优化
module mult_unit #(
    parameter WIDTH = 14
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [2*WIDTH-1:0] product
);
    // 使用专用乘法器资源实现，可优化时序和面积
    assign product = a * b;
    
endmodule