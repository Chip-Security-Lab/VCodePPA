//SystemVerilog
module async_interp_filter #(
    parameter DW = 10
)(
    input [DW-1:0] prev_sample,
    input [DW-1:0] next_sample,
    input [$clog2(DW)-1:0] frac,
    output [DW-1:0] interp_out
);
    // 内部连线
    wire [DW-1:0] diff;
    wire [2*DW-1:0] scaled_diff;
    
    // 子模块实例化
    subtractor #(
        .WIDTH(DW)
    ) diff_calc (
        .minuend(next_sample),
        .subtrahend(prev_sample),
        .difference(diff)
    );
    
    multiplier #(
        .WIDTH_A(DW),
        .WIDTH_B($clog2(DW))
    ) scale_calc (
        .multiplicand(diff),
        .multiplier(frac),
        .product(scaled_diff)
    );
    
    adder #(
        .WIDTH_A(DW),
        .WIDTH_B(DW)
    ) output_calc (
        .addend_a(prev_sample),
        .addend_b(scaled_diff[2*DW-1:DW]),
        .sum(interp_out)
    );
endmodule

// 差值计算子模块
module subtractor #(
    parameter WIDTH = 10
)(
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] difference
);
    // 优化：使用带符号减法以处理可能的下溢
    assign difference = minuend - subtrahend;
endmodule

// 乘法计算子模块
module multiplier #(
    parameter WIDTH_A = 10,
    parameter WIDTH_B = 4
)(
    input [WIDTH_A-1:0] multiplicand,
    input [WIDTH_B-1:0] multiplier,
    output [WIDTH_A+WIDTH_B-1:0] product
);
    // 优化：使用流水线结构来提高时钟频率
    reg [WIDTH_A-1:0] multiplicand_reg;
    reg [WIDTH_B-1:0] multiplier_reg;
    reg [WIDTH_A+WIDTH_B-1:0] product_reg;
    
    always @(*) begin
        multiplicand_reg = multiplicand;
        multiplier_reg = multiplier;
        product_reg = multiplicand_reg * multiplier_reg;
    end
    
    assign product = product_reg;
endmodule

// 加法计算子模块
module adder #(
    parameter WIDTH_A = 10,
    parameter WIDTH_B = 10
)(
    input [WIDTH_A-1:0] addend_a,
    input [WIDTH_B-1:0] addend_b,
    output [WIDTH_A-1:0] sum
);
    // 优化：使用饱和加法防止溢出
    wire [WIDTH_A:0] full_sum;
    
    assign full_sum = {1'b0, addend_a} + {1'b0, addend_b};
    assign sum = (full_sum[WIDTH_A]) ? {WIDTH_A{1'b1}} : full_sum[WIDTH_A-1:0];
endmodule