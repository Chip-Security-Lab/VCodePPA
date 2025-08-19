//SystemVerilog
module async_rgb565_codec (
    input [23:0] rgb_in,
    input alpha_en,
    output reg [15:0] rgb565_out
);
    wire [4:0] red = rgb_in[23:19];
    wire [5:0] green = rgb_in[15:10];
    wire [4:0] blue = rgb_in[7:3];
    
    wire [23:0] multiplied_result;
    
    // 使用Baugh-Wooley乘法器计算rgb_in的某些部分的乘积
    baugh_wooley_multiplier bw_mult (
        .a(rgb_in[23:12]),
        .b(rgb_in[11:0]),
        .product(multiplied_result)
    );
    
    always @(*) begin
        if (alpha_en) begin
            // 使用乘法器计算结果的高位作为红色通道增强
            rgb565_out = {1'b1, multiplied_result[23:19], green, blue};
        end else begin
            rgb565_out = {red, green, blue};
        end
    end
endmodule

// Baugh-Wooley 24位有符号乘法器
module baugh_wooley_multiplier (
    input [11:0] a,
    input [11:0] b,
    output [23:0] product
);
    // 部分积数组
    wire [11:0] pp[11:0];
    wire [23:0] shifted_pp[11:0];
    
    // 生成部分积
    genvar i, j;
    generate
        for (i = 0; i < 11; i = i + 1) begin: pp_gen_normal_rows
            for (j = 0; j < 11; j = j + 1) begin: pp_gen_normal_cols
                assign pp[i][j] = a[i] & b[j];
            end
            // 最后一列取反处理
            assign pp[i][11] = ~(a[i] & b[11]);
        end
    endgenerate
    
    // 最后一行的处理
    generate
        for (j = 0; j < 11; j = j + 1) begin: pp_gen_last_row
            assign pp[11][j] = ~(a[11] & b[j]);
        end
        // 右下角为正
        assign pp[11][11] = a[11] & b[11];
    endgenerate
    
    // 移位部分积
    generate
        for (i = 0; i < 12; i = i + 1) begin: shift_pp
            assign shifted_pp[i] = {{(12-i){1'b0}}, pp[i], {i{1'b0}}};
        end
    endgenerate
    
    // 累加校正位(加1)
    wire [23:0] correction_term;
    assign correction_term = 24'h1_0000; // 在MSB前加1
    
    // 对所有部分积和校正项求和
    wire [23:0] sum;
    assign sum = shifted_pp[0] + shifted_pp[1] + shifted_pp[2] + shifted_pp[3] +
                shifted_pp[4] + shifted_pp[5] + shifted_pp[6] + shifted_pp[7] +
                shifted_pp[8] + shifted_pp[9] + shifted_pp[10] + shifted_pp[11] +
                correction_term;
    
    // 最终结果
    assign product = sum;
endmodule