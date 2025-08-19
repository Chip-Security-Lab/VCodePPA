//SystemVerilog
module float_normalizer #(
    parameter INT_WIDTH = 16,
    parameter EXP_WIDTH = 5,
    parameter FRAC_WIDTH = 10
)(
    input  wire [INT_WIDTH-1:0] int_in,
    output wire [EXP_WIDTH+FRAC_WIDTH-1:0] float_out,
    output reg  overflow
);

    reg [EXP_WIDTH-1:0] exponent;
    reg [FRAC_WIDTH-1:0] fraction;
    integer i, leading_pos;

    // 桶形移位器信号
    reg [INT_WIDTH-1:0] barrel_shifted;
    reg [FRAC_WIDTH-1:0] barrel_fraction;

    // 条件求和减法信号
    wire [INT_WIDTH-1:0] right_shift_amt;
    wire [INT_WIDTH-1:0] left_shift_amt;
    wire [INT_WIDTH-1:0] sub_right_result;
    wire [INT_WIDTH-1:0] sub_left_result;

    // 右移位数 = leading_pos - FRAC_WIDTH + 1
    conditional_sum_subtractor #(
        .WIDTH(INT_WIDTH)
    ) right_subtractor (
        .a({{(INT_WIDTH-5){1'b0}}, leading_pos[4:0]}),
        .b({{(INT_WIDTH-5){1'b0}}, FRAC_WIDTH[4:0] - 1'b1}),
        .diff(right_shift_amt)
    );

    // 左移位数 = FRAC_WIDTH - leading_pos
    conditional_sum_subtractor #(
        .WIDTH(INT_WIDTH)
    ) left_subtractor (
        .a({{(INT_WIDTH-5){1'b0}}, FRAC_WIDTH[4:0]}),
        .b({{(INT_WIDTH-5){1'b0}}, leading_pos[4:0]}),
        .diff(left_shift_amt)
    );

    always @(*) begin
        leading_pos = -1;
        overflow = 1'b0;
        exponent = {EXP_WIDTH{1'b0}};
        fraction = {FRAC_WIDTH{1'b0}};
        barrel_shifted = {INT_WIDTH{1'b0}};
        barrel_fraction = {FRAC_WIDTH{1'b0}};

        // 找最高位的1
        for (i = INT_WIDTH-1; i >= 0; i = i - 1) begin
            if (int_in[i] && leading_pos == -1)
                leading_pos = i;
        end

        if (leading_pos == -1) begin
            // 输入为0
            exponent = {EXP_WIDTH{1'b0}};
            fraction = {FRAC_WIDTH{1'b0}};
        end else if (leading_pos >= FRAC_WIDTH) begin
            exponent = leading_pos[EXP_WIDTH-1:0];
            // 使用条件求和减法器计算右移位数
            barrel_shifted = int_in >> right_shift_amt[4:0];
            barrel_fraction = barrel_shifted[FRAC_WIDTH-1:0];
            fraction = barrel_fraction;
        end else begin
            exponent = leading_pos[EXP_WIDTH-1:0];
            // 使用条件求和减法器计算左移位数
            barrel_shifted = int_in << left_shift_amt[4:0];
            barrel_fraction = barrel_shifted[FRAC_WIDTH-1:0];
            fraction = barrel_fraction;
        end

        // 检查指数是否溢出
        if (leading_pos >= (1 << EXP_WIDTH))
            overflow = 1'b1;
    end

    assign float_out = {exponent, fraction};

endmodule

// 条件求和减法器实现: diff = a - b
module conditional_sum_subtractor #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] diff
);
    wire [WIDTH-1:0] b_invert;
    wire             carry_in;
    wire [WIDTH:0]   carry;
    wire [WIDTH-1:0] sum;

    assign b_invert = ~b;
    assign carry_in = 1'b1; // 加1实现减法

    assign carry[0] = carry_in;

    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin : cond_sum
            assign sum[j] = a[j] ^ b_invert[j] ^ carry[j];
            assign carry[j+1] = (a[j] & b_invert[j]) | (a[j] & carry[j]) | (b_invert[j] & carry[j]);
        end
    endgenerate

    assign diff = sum;

endmodule