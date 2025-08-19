// 顶层模块
module gate_level_adder_top(
    input clk,
    input rst_n,
    input a,
    input b, 
    input cin,
    output reg sum,
    output reg cout
);

    // 内部信号定义
    wire s1_stage1;
    wire c1_stage1, c2_stage1;
    reg s1_stage2;
    reg c1_stage2, c2_stage2;
    reg sum_stage2;

    // 第一级流水线 - 异或运算
    xor_module xor_unit(
        .a(a),
        .b(b),
        .cin(cin),
        .s1(s1_stage1),
        .sum(sum_stage1)
    );

    // 第一级流水线 - 进位计算
    carry_module carry_unit(
        .a(a),
        .b(b),
        .s1(s1_stage1),
        .cin(cin),
        .c1(c1_stage1),
        .c2(c2_stage1),
        .cout(cout_stage1)
    );

    // 第二级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_stage2 <= 1'b0;
            c1_stage2 <= 1'b0;
            c2_stage2 <= 1'b0;
            sum_stage2 <= 1'b0;
        end else begin
            s1_stage2 <= s1_stage1;
            c1_stage2 <= c1_stage1;
            c2_stage2 <= c2_stage1;
            sum_stage2 <= sum_stage1;
        end
    end

    // 输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 1'b0;
            cout <= 1'b0;
        end else begin
            sum <= sum_stage2;
            cout <= c1_stage2 | c2_stage2;
        end
    end

endmodule

// 异或运算子模块
module xor_module(
    input a,
    input b,
    input cin,
    output s1,
    output sum
);

    wire xor_ab;
    xor x1(xor_ab, a, b);
    xor x2(sum, xor_ab, cin);
    assign s1 = xor_ab;

endmodule

// 进位计算子模块
module carry_module(
    input a,
    input b,
    input s1,
    input cin,
    output c1,
    output c2,
    output cout
);

    wire and_ab, and_sc;
    and a1(and_ab, a, b);
    and a2(and_sc, s1, cin);
    or o1(cout, and_ab, and_sc);
    assign c1 = and_ab;
    assign c2 = and_sc;

endmodule