//SystemVerilog
// 顶层模块 - 8位Baugh-Wooley乘法器
module binary_to_onehot_demux (
    input wire [7:0] multiplicand,     // 被乘数
    input wire [7:0] multiplier,       // 乘数
    output wire [15:0] product         // 乘积结果
);
    // 部分积信号
    wire [7:0] pp[7:0];
    wire [15:0] sum_terms[7:0];
    
    // 生成部分积
    baugh_wooley_pp_generator pp_gen (
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .partial_products(pp)
    );
    
    // 部分积累加器
    pp_accumulator pp_acc (
        .partial_products(pp),
        .product(product)
    );
endmodule

// 部分积生成器子模块
module baugh_wooley_pp_generator (
    input wire [7:0] multiplicand,     // 被乘数
    input wire [7:0] multiplier,       // 乘数
    output wire [7:0] partial_products[7:0]  // 部分积
);
    // Baugh-Wooley部分积生成逻辑
    genvar i, j;
    generate
        for (i = 0; i < 7; i = i + 1) begin: rows
            for (j = 0; j < 7; j = j + 1) begin: cols
                assign partial_products[i][j] = multiplicand[j] & multiplier[i];
            end
            // 最高位需要取反（Baugh-Wooley算法特性）
            assign partial_products[i][7] = ~(multiplicand[7] & multiplier[i]);
        end
        
        // 最后一行的处理
        for (j = 0; j < 7; j = j + 1) begin: last_row_cols
            assign partial_products[7][j] = ~(multiplicand[j] & multiplier[7]);
        end
        // 最后一个位置需要置1（Baugh-Wooley算法特性）
        assign partial_products[7][7] = multiplicand[7] & multiplier[7];
    endgenerate
endmodule

// 部分积累加器子模块
module pp_accumulator (
    input wire [7:0] partial_products[7:0],  // 部分积
    output wire [15:0] product               // 乘积结果
);
    // 展开部分积并进行移位
    wire [15:0] shifted_pp[7:0];
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: shift
            assign shifted_pp[i] = {{(8-i){1'b0}}, partial_products[i], {i{1'b0}}};
        end
    endgenerate
    
    // 加入补偿项（Baugh-Wooley算法要求）
    wire [15:0] compensation;
    assign compensation = 16'h0080;  // 补偿项，1在第8位
    
    // 累加所有部分积和补偿项
    assign product = shifted_pp[0] + shifted_pp[1] + shifted_pp[2] + 
                    shifted_pp[3] + shifted_pp[4] + shifted_pp[5] + 
                    shifted_pp[6] + shifted_pp[7] + compensation;
endmodule