module subtractor_4bit_step (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff
);
    wire [3:0] b_comp;
    wire [3:0] sum;
    wire carry_out;
    
    // 计算b的补码
    assign b_comp = ~b + 1'b1;
    
    // 使用4位全加器实现补码加法
    full_adder_4bit adder_inst (
        .a(a),
        .b(b_comp),
        .cin(1'b0),
        .sum(sum),
        .cout(carry_out)
    );
    
    assign diff = sum;
endmodule

module full_adder_4bit (
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [2:0] carry;
    
    full_adder fa0 (
        .a(a[0]),
        .b(b[0]),
        .cin(cin),
        .sum(sum[0]),
        .cout(carry[0])
    );
    
    full_adder fa1 (
        .a(a[1]),
        .b(b[1]),
        .cin(carry[0]),
        .sum(sum[1]),
        .cout(carry[1])
    );
    
    full_adder fa2 (
        .a(a[2]),
        .b(b[2]),
        .cin(carry[1]),
        .sum(sum[2]),
        .cout(carry[2])
    );
    
    full_adder fa3 (
        .a(a[3]),
        .b(b[3]),
        .cin(carry[2]),
        .sum(sum[3]),
        .cout(cout)
    );
endmodule

module full_adder (
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule