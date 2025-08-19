//SystemVerilog
// 顶层模块
module rom_lut #(parameter OUT=24)(
    input [3:0] sel,
    output reg [OUT-1:0] value
);
    wire [7:0] product;
    
    multiplier_controller mult_ctrl (
        .sel(sel),
        .product(product)
    );
    
    always @(*) begin
        value = {16'b0, product};
    end
endmodule

// 乘法器控制器模块
module multiplier_controller(
    input [3:0] sel,
    output [7:0] product
);
    wire [3:0] multiplier = sel;
    wire [3:0] multiplicand = 4'b0001;
    
    pipelined_multiplier_4bit mult_inst (
        .clk(clk),
        .rst_n(rst_n),
        .a(multiplier),
        .b(multiplicand),
        .p(product)
    );
endmodule

// 流水线乘法器模块
module pipelined_multiplier_4bit(
    input clk,
    input rst_n,
    input [3:0] a,
    input [3:0] b,
    output reg [7:0] p
);
    wire [3:0] pp0, pp1, pp2, pp3;
    wire [4:0] sum1, carry1;
    wire [3:0] sum2, carry2;
    wire [7:0] final_sum, final_carry;
    
    partial_product_gen pp_gen (
        .a(a),
        .b(b),
        .pp0(pp0),
        .pp1(pp1),
        .pp2(pp2),
        .pp3(pp3)
    );
    
    compressor_stage1 comp1 (
        .pp0(pp0),
        .pp1(pp1),
        .pp2(pp2),
        .pp3(pp3),
        .sum1(sum1),
        .carry1(carry1),
        .sum2(sum2),
        .carry2(carry2)
    );
    
    final_adder final_add (
        .sum1(sum1),
        .sum2(sum2),
        .carry1(carry1),
        .carry2(carry2),
        .final_sum(final_sum),
        .final_carry(final_carry)
    );
    
    pipeline_regs pipe_regs (
        .clk(clk),
        .rst_n(rst_n),
        .pp0(pp0),
        .pp1(pp1),
        .pp2(pp2),
        .pp3(pp3),
        .sum1(sum1),
        .carry1(carry1),
        .sum2(sum2),
        .carry2(carry2),
        .final_sum(final_sum),
        .final_carry(final_carry),
        .p(p)
    );
endmodule

// 部分积生成模块
module partial_product_gen(
    input [3:0] a,
    input [3:0] b,
    output [3:0] pp0,
    output [3:0] pp1,
    output [3:0] pp2,
    output [3:0] pp3
);
    assign pp0 = a & {4{b[0]}};
    assign pp1 = a & {4{b[1]}};
    assign pp2 = a & {4{b[2]}};
    assign pp3 = a & {4{b[3]}};
endmodule

// 第一级压缩模块
module compressor_stage1(
    input [3:0] pp0,
    input [3:0] pp1,
    input [3:0] pp2,
    input [3:0] pp3,
    output [4:0] sum1,
    output [4:0] carry1,
    output [3:0] sum2,
    output [3:0] carry2
);
    assign sum1[0] = pp0[0];
    assign carry1[0] = 1'b0;
    
    full_adder fa1_1(pp0[1], pp1[0], 1'b0, sum1[1], carry1[1]);
    full_adder fa1_2(pp0[2], pp1[1], pp2[0], sum1[2], carry1[2]);
    full_adder fa1_3(pp0[3], pp1[2], pp2[1], sum1[3], carry1[3]);
    full_adder fa1_4(pp1[3], pp2[2], pp3[1], sum1[4], carry1[4]);
    full_adder fa2_1(pp2[3], pp3[2], carry1[3], sum2[0], carry2[0]);
    full_adder fa2_2(pp3[3], carry1[4], carry2[0], sum2[1], carry2[1]);
endmodule

// 最终加法器模块
module final_adder(
    input [4:0] sum1,
    input [3:0] sum2,
    input [4:0] carry1,
    input [3:0] carry2,
    output [7:0] final_sum,
    output [7:0] final_carry
);
    assign final_sum[0] = sum1[0];
    assign final_sum[1] = sum1[1];
    assign final_sum[2] = sum1[2];
    assign final_sum[3] = sum1[3];
    assign final_sum[4] = sum1[4];
    assign final_sum[5] = sum2[0];
    assign final_sum[6] = sum2[1];
    assign final_sum[7] = carry2[1];
    
    assign final_carry = {carry2[1], carry2[0], carry1[4:0]};
endmodule

// 流水线寄存器模块
module pipeline_regs(
    input clk,
    input rst_n,
    input [3:0] pp0,
    input [3:0] pp1,
    input [3:0] pp2,
    input [3:0] pp3,
    input [4:0] sum1,
    input [4:0] carry1,
    input [3:0] sum2,
    input [3:0] carry2,
    input [7:0] final_sum,
    input [7:0] final_carry,
    output reg [7:0] p
);
    reg [3:0] pp0_reg, pp1_reg, pp2_reg, pp3_reg;
    reg [4:0] sum1_reg, carry1_reg;
    reg [3:0] sum2_reg, carry2_reg;
    reg [7:0] final_sum_reg, final_carry_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pp0_reg <= 4'b0;
            pp1_reg <= 4'b0;
            pp2_reg <= 4'b0;
            pp3_reg <= 4'b0;
            sum1_reg <= 5'b0;
            carry1_reg <= 5'b0;
            sum2_reg <= 4'b0;
            carry2_reg <= 4'b0;
            final_sum_reg <= 8'b0;
            final_carry_reg <= 8'b0;
            p <= 8'b0;
        end else begin
            pp0_reg <= pp0;
            pp1_reg <= pp1;
            pp2_reg <= pp2;
            pp3_reg <= pp3;
            sum1_reg <= sum1;
            carry1_reg <= carry1;
            sum2_reg <= sum2;
            carry2_reg <= carry2;
            final_sum_reg <= final_sum;
            final_carry_reg <= final_carry;
            p <= final_sum_reg + final_carry_reg;
        end
    end
endmodule

// 全加器模块
module full_adder(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule