//SystemVerilog
// Top level module - Baugh-Wooley 乘法器 (39位)
module hamming_xor_tree(
    input [31:0] data,
    output [38:0] encoded
);

    // Internal signals
    wire [38:0] multiplicand;
    wire [38:0] multiplier;
    wire [38:0] product;
    
    // 将输入数据扩展到39位
    assign multiplicand = {7'b0000000, data};
    assign multiplier = 39'h0000000FF; // 固定乘数 (可以根据需要调整)
    
    // 实例化Baugh-Wooley乘法器
    baugh_wooley_multiplier bw_mult_inst(
        .a(multiplicand),
        .b(multiplier),
        .p(product)
    );
    
    // 输出编码结果
    assign encoded[6:0] = product[6:0];
    assign encoded[38:7] = data;

endmodule

// Baugh-Wooley 39位乘法器
module baugh_wooley_multiplier(
    input [38:0] a,  // 被乘数
    input [38:0] b,  // 乘数
    output [38:0] p  // 乘积 (使用39位，但实际上完整乘积应该是77位)
);
    
    // 部分积矩阵
    wire [38:0] pp [38:0];
    // 部分积和
    wire [76:0] sum_stages [38:0];
    
    // 生成部分积
    genvar i, j;
    generate
        for(i=0; i<38; i=i+1) begin: gen_pp_rows
            for(j=0; j<38; j=j+1) begin: gen_pp_cols
                assign pp[i][j] = a[j] & b[i];
            end
            // 根据Baugh-Wooley算法处理最高位
            assign pp[i][38] = ~(a[38] & b[i]);
        end
        
        // 最后一行的处理
        for(j=0; j<38; j=j+1) begin: gen_last_pp_row
            assign pp[38][j] = ~(a[j] & b[38]);
        end
        // 最右下角的乘积项
        assign pp[38][38] = a[38] & b[38];
    endgenerate
    
    // 求和行
    assign sum_stages[0] = {39'b0, pp[0]};
    
    generate
        for(i=1; i<39; i=i+1) begin: gen_sum_stages
            assign sum_stages[i] = sum_stages[i-1] + ({39'b0, pp[i]} << i);
        end
    endgenerate
    
    // 增加额外的"1"到最终和，这是Baugh-Wooley算法的要求
    wire [76:0] final_sum;
    assign final_sum = sum_stages[38] + (1'b1 << 76);
    
    // 输出结果的低39位
    assign p = final_sum[38:0];
    
endmodule