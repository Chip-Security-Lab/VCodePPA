module subtractor_8bit_borrow_detect (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff,
    output borrow
);

    wire [7:0] b_comp;
    wire [7:0] sum;
    wire [8:0] carry;

    // 计算b的补码
    assign b_comp = ~b + 1'b1;

    // 初始化进位
    assign carry[0] = 1'b0;

    // 8位全加器实现借位减法
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : full_adder
            assign {carry[i+1], sum[i]} = a[i] + b_comp[i] + carry[i];
        end
    endgenerate

    // 输出结果
    assign diff = sum;
    assign borrow = carry[8];

endmodule