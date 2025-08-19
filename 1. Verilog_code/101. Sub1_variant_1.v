// 补码计算子模块
module complement_calculator(
    input [7:0] b,
    output [7:0] b_comp
);
    assign b_comp = ~b;
endmodule

// 进位链计算子模块
module carry_chain(
    input [7:0] a,
    input [7:0] b_comp,
    output [7:0] carry
);
    assign carry[0] = 1'b1;
    assign carry[1] = (a[0] & b_comp[0]) | (a[0] & carry[0]) | (b_comp[0] & carry[0]);
    assign carry[2] = (a[1] & b_comp[1]) | (a[1] & carry[1]) | (b_comp[1] & carry[1]);
    assign carry[3] = (a[2] & b_comp[2]) | (a[2] & carry[2]) | (b_comp[2] & carry[2]);
    assign carry[4] = (a[3] & b_comp[3]) | (a[3] & carry[3]) | (b_comp[3] & carry[3]);
    assign carry[5] = (a[4] & b_comp[4]) | (a[4] & carry[4]) | (b_comp[4] & carry[4]);
    assign carry[6] = (a[5] & b_comp[5]) | (a[5] & carry[5]) | (b_comp[5] & carry[5]);
    assign carry[7] = (a[6] & b_comp[6]) | (a[6] & carry[6]) | (b_comp[6] & carry[6]);
endmodule

// 最终结果计算子模块
module sum_calculator(
    input [7:0] a,
    input [7:0] b_comp,
    input [7:0] carry,
    output [7:0] sum
);
    assign sum[0] = a[0] ^ b_comp[0] ^ carry[0];
    assign sum[1] = a[1] ^ b_comp[1] ^ carry[1];
    assign sum[2] = a[2] ^ b_comp[2] ^ carry[2];
    assign sum[3] = a[3] ^ b_comp[3] ^ carry[3];
    assign sum[4] = a[4] ^ b_comp[4] ^ carry[4];
    assign sum[5] = a[5] ^ b_comp[5] ^ carry[5];
    assign sum[6] = a[6] ^ b_comp[6] ^ carry[6];
    assign sum[7] = a[7] ^ b_comp[7] ^ carry[7];
endmodule

// 顶层模块
module Sub1(
    input [7:0] a,
    input [7:0] b,
    output [7:0] result
);
    wire [7:0] b_comp;
    wire [7:0] carry;
    wire [7:0] sum;
    
    complement_calculator comp_calc(
        .b(b),
        .b_comp(b_comp)
    );
    
    carry_chain carry_calc(
        .a(a),
        .b_comp(b_comp),
        .carry(carry)
    );
    
    sum_calculator sum_calc(
        .a(a),
        .b_comp(b_comp),
        .carry(carry),
        .sum(sum)
    );
    
    assign result = sum;
endmodule