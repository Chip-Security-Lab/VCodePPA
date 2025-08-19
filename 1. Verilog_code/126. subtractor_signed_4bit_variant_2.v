module subtractor_signed_4bit (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] diff
);

    adder_signed_4bit adder_inst (
        .a(a),
        .b(~b + 1'b1),
        .sum(diff)
    );

endmodule

module adder_signed_4bit (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] sum
);

    wire [3:0] carry;
    wire [3:0] sum_temp;

    // 展开进位链加法器
    assign {carry[0], sum_temp[0]} = a[0] + b[0];
    assign {carry[1], sum_temp[1]} = a[1] + b[1] + carry[0];
    assign {carry[2], sum_temp[2]} = a[2] + b[2] + carry[1];
    assign {carry[3], sum_temp[3]} = a[3] + b[3] + carry[2];

    assign sum = sum_temp;

endmodule