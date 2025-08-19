//SystemVerilog
module wallace_multiplier_8bit(
    input [7:0] a,
    input [7:0] b,
    output [15:0] product
);
    // 部分积生成
    wire [7:0][7:0] pp;
    
    // 生成部分积
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : pp_gen_i
            for (j = 0; j < 8; j = j + 1) begin : pp_gen_j
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Wallace树压缩阶段
    // 第一阶段：将8个部分积压缩为6个
    wire [14:0] s1_0, s1_1, c1_0, c1_1;
    
    full_adder_array #(8) fa1_0 (
        .a({1'b0, pp[0][7:1]}),
        .b(pp[1][7:0]),
        .cin(8'b0),
        .sum(s1_0[7:0]),
        .cout(c1_0[7:0])
    );
    
    full_adder_array #(8) fa1_1 (
        .a(pp[2][7:0]),
        .b(pp[3][7:0]),
        .cin(8'b0),
        .sum(s1_1[7:0]),
        .cout(c1_1[7:0])
    );
    
    assign s1_0[8] = pp[0][0];
    assign s1_0[14:9] = 6'b0;
    assign c1_0[14:8] = 7'b0;
    
    assign s1_1[14:8] = 7'b0;
    assign c1_1[14:8] = 7'b0;
    
    // 第二阶段：将6个部分积压缩为4个
    wire [14:0] s2_0, s2_1, c2_0, c2_1;
    
    full_adder_array #(8) fa2_0 (
        .a(pp[4][7:0]),
        .b(pp[5][7:0]),
        .cin(8'b0),
        .sum(s2_0[7:0]),
        .cout(c2_0[7:0])
    );
    
    assign s2_0[14:8] = 7'b0;
    assign c2_0[14:8] = 7'b0;
    
    assign s2_1 = {7'b0, pp[6][7:0]};
    assign c2_1 = {7'b0, pp[7][7:0]};
    
    // 第三阶段：将4个部分积压缩为3个
    wire [14:0] s3_0, c3_0, s3_1;
    
    full_adder_array #(15) fa3_0 (
        .a(s1_0),
        .b({c1_0[13:0], 1'b0}),
        .cin(15'b0),
        .sum(s3_0),
        .cout(c3_0)
    );
    
    assign s3_1 = s1_1;
    
    // 第四阶段：将3个部分积压缩为2个
    wire [14:0] s4_0, c4_0;
    
    full_adder_array #(15) fa4_0 (
        .a(s3_0),
        .b({c3_0[13:0], 1'b0}),
        .cin(s3_1),
        .sum(s4_0),
        .cout(c4_0)
    );
    
    // 第五阶段：将2个部分积压缩为2个 (重组)
    wire [14:0] s5_0, c5_0;
    
    full_adder_array #(15) fa5_0 (
        .a(s2_0),
        .b({c2_0[13:0], 1'b0}),
        .cin(s2_1),
        .sum(s5_0),
        .cout(c5_0)
    );
    
    // 第六阶段：将4个部分积压缩为2个
    wire [14:0] s6_0, c6_0;
    
    full_adder_array #(15) fa6_0 (
        .a(s4_0),
        .b({c4_0[13:0], 1'b0}),
        .cin(s5_0),
        .sum(s6_0),
        .cout(c6_0)
    );
    
    // 第七阶段：将剩余的部分积压缩为2个
    wire [14:0] s7_0, c7_0;
    
    full_adder_array #(15) fa7_0 (
        .a(s6_0),
        .b({c6_0[13:0], 1'b0}),
        .cin({c5_0[13:0], 1'b0}),
        .sum(s7_0),
        .cout(c7_0)
    );
    
    // 最后加法阶段 (进位传播加法器)
    assign product = {s7_0, 1'b0} + {c7_0, 1'b0} + {c2_1, 1'b0};
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

// 全加器阵列模块
module full_adder_array #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [WIDTH-1:0] cin,
    output [WIDTH-1:0] sum,
    output [WIDTH-1:0] cout
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : fa_loop
            full_adder fa_inst (
                .a(a[i]),
                .b(b[i]),
                .cin(cin[i]),
                .sum(sum[i]),
                .cout(cout[i])
            );
        end
    endgenerate
endmodule