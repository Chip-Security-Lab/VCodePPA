//SystemVerilog
module signed_multiply_subtract (
    input signed [7:0] a,
    input signed [7:0] b,
    input signed [7:0] c,
    output signed [15:0] result
);
    wire signed [15:0] product;
    
    baugh_wooley_multiplier bw_mult (
        .a(a),
        .b(b),
        .product(product)
    );
    
    assign result = product - c;
endmodule

module baugh_wooley_multiplier (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [15:0] product
);
    wire [7:0] pp [7:0];
    wire [15:0] sum;
    
    // 展开部分积生成
    assign pp[0][0] = a[0] & b[0];
    assign pp[0][1] = a[0] & b[1];
    assign pp[0][2] = a[0] & b[2];
    assign pp[0][3] = a[0] & b[3];
    assign pp[0][4] = a[0] & b[4];
    assign pp[0][5] = a[0] & b[5];
    assign pp[0][6] = a[0] & b[6];
    assign pp[0][7] = ~(a[0] & b[7]);

    assign pp[1][0] = a[1] & b[0];
    assign pp[1][1] = a[1] & b[1];
    assign pp[1][2] = a[1] & b[2];
    assign pp[1][3] = a[1] & b[3];
    assign pp[1][4] = a[1] & b[4];
    assign pp[1][5] = a[1] & b[5];
    assign pp[1][6] = a[1] & b[6];
    assign pp[1][7] = ~(a[1] & b[7]);

    assign pp[2][0] = a[2] & b[0];
    assign pp[2][1] = a[2] & b[1];
    assign pp[2][2] = a[2] & b[2];
    assign pp[2][3] = a[2] & b[3];
    assign pp[2][4] = a[2] & b[4];
    assign pp[2][5] = a[2] & b[5];
    assign pp[2][6] = a[2] & b[6];
    assign pp[2][7] = ~(a[2] & b[7]);

    assign pp[3][0] = a[3] & b[0];
    assign pp[3][1] = a[3] & b[1];
    assign pp[3][2] = a[3] & b[2];
    assign pp[3][3] = a[3] & b[3];
    assign pp[3][4] = a[3] & b[4];
    assign pp[3][5] = a[3] & b[5];
    assign pp[3][6] = a[3] & b[6];
    assign pp[3][7] = ~(a[3] & b[7]);

    assign pp[4][0] = a[4] & b[0];
    assign pp[4][1] = a[4] & b[1];
    assign pp[4][2] = a[4] & b[2];
    assign pp[4][3] = a[4] & b[3];
    assign pp[4][4] = a[4] & b[4];
    assign pp[4][5] = a[4] & b[5];
    assign pp[4][6] = a[4] & b[6];
    assign pp[4][7] = ~(a[4] & b[7]);

    assign pp[5][0] = a[5] & b[0];
    assign pp[5][1] = a[5] & b[1];
    assign pp[5][2] = a[5] & b[2];
    assign pp[5][3] = a[5] & b[3];
    assign pp[5][4] = a[5] & b[4];
    assign pp[5][5] = a[5] & b[5];
    assign pp[5][6] = a[5] & b[6];
    assign pp[5][7] = ~(a[5] & b[7]);

    assign pp[6][0] = a[6] & b[0];
    assign pp[6][1] = a[6] & b[1];
    assign pp[6][2] = a[6] & b[2];
    assign pp[6][3] = a[6] & b[3];
    assign pp[6][4] = a[6] & b[4];
    assign pp[6][5] = a[6] & b[5];
    assign pp[6][6] = a[6] & b[6];
    assign pp[6][7] = ~(a[6] & b[7]);

    assign pp[7][0] = ~(a[7] & b[0]);
    assign pp[7][1] = ~(a[7] & b[1]);
    assign pp[7][2] = ~(a[7] & b[2]);
    assign pp[7][3] = ~(a[7] & b[3]);
    assign pp[7][4] = ~(a[7] & b[4]);
    assign pp[7][5] = ~(a[7] & b[5]);
    assign pp[7][6] = ~(a[7] & b[6]);
    assign pp[7][7] = a[7] & b[7];

    // 展开部分积移位和累加
    wire [15:0] shifted_pp [7:0];
    
    assign shifted_pp[0] = {8'b0, pp[0]};
    assign shifted_pp[1] = {7'b0, pp[1], 1'b0};
    assign shifted_pp[2] = {6'b0, pp[2], 2'b0};
    assign shifted_pp[3] = {5'b0, pp[3], 3'b0};
    assign shifted_pp[4] = {4'b0, pp[4], 4'b0};
    assign shifted_pp[5] = {3'b0, pp[5], 5'b0};
    assign shifted_pp[6] = {2'b0, pp[6], 6'b0};
    assign shifted_pp[7] = {1'b0, pp[7], 7'b0};

    // 使用加法树优化累加
    wire [15:0] sum1, sum2, sum3;
    
    assign sum1 = shifted_pp[0] + shifted_pp[1];
    assign sum2 = shifted_pp[2] + shifted_pp[3];
    assign sum3 = shifted_pp[4] + shifted_pp[5];
    assign sum = ((sum1 + sum2) + (sum3 + shifted_pp[6])) + shifted_pp[7] + 16'h0101;
    
    assign product = sum;
endmodule