//SystemVerilog
module multi_channel_wallace_multiplier #(
    parameter CHANNELS = 4,
    parameter WIDTH = 8
)(
    input [CHANNELS*WIDTH-1:0] ch_data_a,
    input [CHANNELS*WIDTH-1:0] ch_data_b,
    output [CHANNELS*2*WIDTH-1:0] ch_product
);
    genvar i;
    generate
        for (i=0; i<CHANNELS; i=i+1) begin : gen_multiplier
            wire [WIDTH-1:0] data_a = ch_data_a[i*WIDTH +: WIDTH];
            wire [WIDTH-1:0] data_b = ch_data_b[i*WIDTH +: WIDTH];
            wire [2*WIDTH-1:0] product;
            
            wallace_tree_multiplier #(
                .WIDTH(WIDTH)
            ) wallace_mult (
                .a(data_a),
                .b(data_b),
                .product(product)
            );
            
            assign ch_product[i*2*WIDTH +: 2*WIDTH] = product;
        end
    endgenerate
endmodule

module wallace_tree_multiplier #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [2*WIDTH-1:0] product
);
    // 生成部分积
    wire [WIDTH-1:0] pp[WIDTH-1:0];
    
    genvar i, j;
    generate
        for (i=0; i<WIDTH; i=i+1) begin : gen_pp
            for (j=0; j<WIDTH; j=j+1) begin : gen_pp_bit
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Wallace树结构的第一层
    // 8位乘法将生成8个部分积
    
    // 第1层: 将8个部分积分成5个中间结果
    wire [WIDTH+0:0] s1_0, c1_0;  // 3:2压缩器1的结果
    wire [WIDTH+0:0] s1_1, c1_1;  // 3:2压缩器2的结果
    
    // 第1层压缩器
    compressor_3_2 #(WIDTH+1) comp1_0 (
        .a({1'b0, pp[0]}),
        .b({1'b0, pp[1]}),
        .c({1'b0, pp[2]}),
        .sum(s1_0),
        .carry(c1_0)
    );
    
    compressor_3_2 #(WIDTH+1) comp1_1 (
        .a({1'b0, pp[3]}),
        .b({1'b0, pp[4]}),
        .c({1'b0, pp[5]}),
        .sum(s1_1),
        .carry(c1_1)
    );
    
    // 第2层: 将5个中间结果压缩为3个
    wire [WIDTH+2:0] s2_0, c2_0;  // 3:2压缩器结果
    
    compressor_3_2 #(WIDTH+3) comp2_0 (
        .a({2'b0, s1_0}),
        .b({1'b0, c1_0, 1'b0}),
        .c({2'b0, s1_1}),
        .sum(s2_0),
        .carry(c2_0)
    );
    
    // 第3层: 将3个中间结果压缩为2个
    wire [WIDTH+4:0] s3_0, c3_0;  // 3:2压缩器结果
    
    compressor_3_2 #(WIDTH+5) comp3_0 (
        .a({2'b0, s2_0}),
        .b({1'b0, c2_0, 1'b0}),
        .c({4'b0, {1'b0, pp[6]}}),
        .sum(s3_0),
        .carry(c3_0)
    );
    
    // 最终阶段: 将最后3个中间结果压缩为2个
    wire [WIDTH+6:0] s4_0, c4_0;  // 3:2压缩器结果
    
    compressor_3_2 #(WIDTH+7) comp4_0 (
        .a({2'b0, s3_0}),
        .b({1'b0, c3_0, 1'b0}),
        .c({6'b0, {1'b0, pp[7]}}),
        .sum(s4_0),
        .carry(c4_0)
    );
    
    // 最终结果通过全加器进位进位链计算
    wire [2*WIDTH-1:0] final_sum;
    wire [2*WIDTH:0] carries;
    
    assign carries[0] = 1'b0;
    
    generate
        for (i=0; i<2*WIDTH; i=i+1) begin : gen_final_adder
            wire a_bit = (i < WIDTH+7) ? s4_0[i] : 1'b0;
            wire b_bit = (i < WIDTH+7) ? (i > 0 ? c4_0[i-1] : 1'b0) : 1'b0;
            
            assign final_sum[i] = a_bit ^ b_bit ^ carries[i];
            assign carries[i+1] = (a_bit & b_bit) | (a_bit & carries[i]) | (b_bit & carries[i]);
        end
    endgenerate
    
    assign product = final_sum;
endmodule

// 3:2压缩器模块 (全加器树)
module compressor_3_2 #(
    parameter WIDTH = 9
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [WIDTH-1:0] c,
    output [WIDTH-1:0] sum,
    output [WIDTH-1:0] carry
);
    genvar i;
    generate
        for (i=0; i<WIDTH; i=i+1) begin : gen_compressor
            assign sum[i] = a[i] ^ b[i] ^ c[i];
            assign carry[i] = (a[i] & b[i]) | (b[i] & c[i]) | (a[i] & c[i]);
        end
    endgenerate
endmodule