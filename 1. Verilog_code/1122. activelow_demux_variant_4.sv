//SystemVerilog
module activelow_demux (
    input wire data_in,                  // Input data (active high)
    input wire [1:0] addr,               // Address selection
    output reg [3:0] out_n               // Active-low outputs
);
    // 将输入转换为乘法操作数
    wire [3:0] mult_a, mult_b;
    wire [7:0] mult_result;
    
    // 从输入信号生成乘法操作数
    assign mult_a = {addr, addr};
    assign mult_b = {data_in, data_in, data_in, data_in};
    
    // 实例化华莱士树乘法器
    wallace_tree_4bit multiplier (
        .a(mult_a),
        .b(mult_b),
        .product(mult_result)
    );
    
    // 保持原始模块的功能行为
    always @(*) begin
        if (!data_in) begin
            out_n = 4'b1111;  // ~4'b0000 when data_in is 0
        end else if (addr == 2'b00) begin
            out_n = 4'b1110;  // ~4'b0001
        end else if (addr == 2'b01) begin
            out_n = 4'b1101;  // ~4'b0010
        end else if (addr == 2'b10) begin
            out_n = 4'b1011;  // ~4'b0100
        end else if (addr == 2'b11) begin
            out_n = 4'b0111;  // ~4'b1000
        end else begin
            out_n = 4'b1111;  // Default case
        end
    end
endmodule

module wallace_tree_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [7:0] product
);
    // 部分积生成
    wire [3:0] pp0, pp1, pp2, pp3;
    
    assign pp0 = b[0] ? a : 4'b0000;
    assign pp1 = b[1] ? a : 4'b0000;
    assign pp2 = b[2] ? a : 4'b0000;
    assign pp3 = b[3] ? a : 4'b0000;
    
    // 第一级压缩 - 部分积相加
    wire [4:0] s1_1, c1_1;  // 第一级的和与进位
    wire [4:0] s1_2, c1_2;  // 第一级的和与进位
    
    // 第一组3:2压缩
    full_adder fa1_0 (.a(pp0[0]), .b(pp1[0]), .cin(pp2[0]), .sum(s1_1[0]), .cout(c1_1[0]));
    full_adder fa1_1 (.a(pp0[1]), .b(pp1[1]), .cin(pp2[1]), .sum(s1_1[1]), .cout(c1_1[1]));
    full_adder fa1_2 (.a(pp0[2]), .b(pp1[2]), .cin(pp2[2]), .sum(s1_1[2]), .cout(c1_1[2]));
    full_adder fa1_3 (.a(pp0[3]), .b(pp1[3]), .cin(pp2[3]), .sum(s1_1[3]), .cout(c1_1[3]));
    
    // 第二级压缩
    wire [5:0] s2, c2;  // 第二级的和与进位
    
    // 处理第一级结果和剩余部分积
    assign s1_1[4] = 1'b0;
    assign c1_1[4] = 1'b0;
    
    full_adder fa2_0 (.a(s1_1[0]), .b(pp3[0]), .cin(1'b0), .sum(s2[0]), .cout(c2[0]));
    full_adder fa2_1 (.a(s1_1[1]), .b(pp3[1]), .cin(c1_1[0]), .sum(s2[1]), .cout(c2[1]));
    full_adder fa2_2 (.a(s1_1[2]), .b(pp3[2]), .cin(c1_1[1]), .sum(s2[2]), .cout(c2[2]));
    full_adder fa2_3 (.a(s1_1[3]), .b(pp3[3]), .cin(c1_1[2]), .sum(s2[3]), .cout(c2[3]));
    full_adder fa2_4 (.a(s1_1[4]), .b(1'b0), .cin(c1_1[3]), .sum(s2[4]), .cout(c2[4]));
    
    // 最终加法 - 行波进位加法器
    assign product[0] = s2[0];
    wire [5:0] final_sum;
    wire [5:0] final_carry;
    
    half_adder ha_f0 (.a(s2[1]), .b(c2[0]), .sum(product[1]), .cout(final_carry[0]));
    full_adder fa_f1 (.a(s2[2]), .b(c2[1]), .cin(final_carry[0]), .sum(product[2]), .cout(final_carry[1]));
    full_adder fa_f2 (.a(s2[3]), .b(c2[2]), .cin(final_carry[1]), .sum(product[3]), .cout(final_carry[2]));
    full_adder fa_f3 (.a(s2[4]), .b(c2[3]), .cin(final_carry[2]), .sum(product[4]), .cout(final_carry[3]));
    full_adder fa_f4 (.a(1'b0), .b(c2[4]), .cin(final_carry[3]), .sum(product[5]), .cout(product[6]));
    
    assign product[7] = 1'b0; // 4位×4位乘法最高位
endmodule

module full_adder (
    input wire a, b, cin,
    output wire sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

module half_adder (
    input wire a, b,
    output wire sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule