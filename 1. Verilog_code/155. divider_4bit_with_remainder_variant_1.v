// 顶层模块
module divider_4bit_with_remainder (
    input [3:0] a,
    input [3:0] b,
    output [3:0] quotient,
    output [3:0] remainder
);

    wire [3:0] partial_remainder;
    wire [3:0] next_remainder;
    wire [3:0] next_quotient;

    // 实例化除法迭代单元
    divider_iteration_unit iter_unit (
        .dividend(a),
        .divisor(b),
        .partial_remainder(partial_remainder),
        .next_remainder(next_remainder),
        .next_quotient(next_quotient)
    );

    // 实例化结果输出单元
    result_output_unit output_unit (
        .next_quotient(next_quotient),
        .final_remainder(partial_remainder),
        .quotient(quotient),
        .remainder(remainder)
    );

endmodule

// 除法迭代单元
module divider_iteration_unit (
    input [3:0] dividend,
    input [3:0] divisor,
    output reg [3:0] partial_remainder,
    output reg [3:0] next_remainder,
    output reg [3:0] next_quotient
);

    integer i;

    always @(*) begin
        partial_remainder = 4'b0;
        next_remainder = 4'b0;
        next_quotient = 4'b0;

        for (i = 3; i >= 0; i = i - 1) begin
            partial_remainder = {partial_remainder[2:0], dividend[i]};
            
            if (partial_remainder >= divisor) begin
                next_remainder = partial_remainder - divisor;
                next_quotient[i] = 1'b1;
            end else begin
                next_remainder = partial_remainder;
                next_quotient[i] = 1'b0;
            end
            
            partial_remainder = next_remainder;
        end
    end

endmodule

// 结果输出单元
module result_output_unit (
    input [3:0] next_quotient,
    input [3:0] final_remainder,
    output reg [3:0] quotient,
    output reg [3:0] remainder
);

    always @(*) begin
        quotient = next_quotient;
        remainder = final_remainder;
    end

endmodule