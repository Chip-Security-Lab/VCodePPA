//SystemVerilog
// 顶层模块：三输入反相或门，采用流水线结构优化数据通路
module nor3_inverted (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        A,
    input  wire        B,
    input  wire        C,
    output wire        Y
);

    // Stage 1: 输入寄存器级
    reg A_stage1;
    reg B_stage1;
    reg C_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_stage1 <= 1'b0;
            B_stage1 <= 1'b0;
            C_stage1 <= 1'b0;
        end else begin
            A_stage1 <= A;
            B_stage1 <= B;
            C_stage1 <= C;
        end
    end

    // Stage 2: 组合逻辑，A和B或运算
    wire ab_or_stage2;
    or2 u_or2_ab_stage2 (
        .in1(A_stage1),
        .in2(B_stage1),
        .out(ab_or_stage2)
    );

    // Stage 2: 寄存器级，锁存ab_or和C
    reg ab_or_stage2_reg;
    reg C_stage2_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ab_or_stage2_reg <= 1'b0;
            C_stage2_reg     <= 1'b0;
        end else begin
            ab_or_stage2_reg <= ab_or_stage2;
            C_stage2_reg     <= C_stage1;
        end
    end

    // Stage 3: 组合逻辑，ab_or和C或运算
    wire abc_or_stage3;
    or2 u_or2_abc_stage3 (
        .in1(ab_or_stage2_reg),
        .in2(C_stage2_reg),
        .out(abc_or_stage3)
    );

    // Stage 3: 寄存器级，锁存abc_or
    reg abc_or_stage3_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abc_or_stage3_reg <= 1'b0;
        end else begin
            abc_or_stage3_reg <= abc_or_stage3;
        end
    end

    // Stage 4: 反相输出
    wire Y_internal;
    inv u_inv_final (
        .in(abc_or_stage3_reg),
        .out(Y_internal)
    );

    // Stage 4: 输出寄存器
    reg Y_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y_reg <= 1'b0;
        end else begin
            Y_reg <= Y_internal;
        end
    end

    assign Y = Y_reg;

endmodule

// 子模块：二输入或门
module or2 (
    input  wire in1,
    input  wire in2,
    output wire out
);
    assign out = in1 | in2;
endmodule

// 子模块：反相器
module inv (
    input  wire in,
    output wire out
);
    assign out = ~in;
endmodule