module subtractor_conditional (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] res
);

wire [7:0] b_comp;
wire [7:0] sum;
wire carry_out;

// 条件求和减法算法实现
assign b_comp = comp_result ? ~b : b;
assign {carry_out, sum} = a + b_comp + comp_result;
assign res = comp_result ? sum : 8'b0;

// 比较器逻辑
wire comp_result;
assign comp_result = (a >= b);

endmodule