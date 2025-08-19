//SystemVerilog
module priority_decoder(
    input [7:0] req_in,
    output reg [2:0] grant_addr,
    output reg valid,
    // 增加乘法器接口
    input [7:0] multiplicand,
    input [7:0] multiplier,
    output [15:0] product
);
    // 原优先编码器逻辑
    always @(*) begin
        valid = 1'b0;
        grant_addr = 3'b000;
        if (req_in[7]) begin grant_addr = 3'b111; valid = 1'b1; end
        else if (req_in[6]) begin grant_addr = 3'b110; valid = 1'b1; end
        else if (req_in[5]) begin grant_addr = 3'b101; valid = 1'b1; end
        else if (req_in[4]) begin grant_addr = 3'b100; valid = 1'b1; end
        else if (req_in[3]) begin grant_addr = 3'b011; valid = 1'b1; end
        else if (req_in[2]) begin grant_addr = 3'b010; valid = 1'b1; end
        else if (req_in[1]) begin grant_addr = 3'b001; valid = 1'b1; end
        else if (req_in[0]) begin grant_addr = 3'b000; valid = 1'b1; end
    end
    
    // 实例化Baugh-Wooley乘法器
    baugh_wooley_multiplier bw_mult (
        .a(multiplicand),
        .b(multiplier),
        .p(product)
    );
    
endmodule

// Baugh-Wooley 8位乘法器实现
module baugh_wooley_multiplier(
    input [7:0] a,   // 被乘数
    input [7:0] b,   // 乘数
    output [15:0] p  // 乘积
);
    wire [7:0][7:0] partial_products;
    wire [15:0] sum;
    
    // 生成部分积
    // 对于Baugh-Wooley算法，需要特殊处理符号位的乘法
    genvar i, j;
    generate
        for (i = 0; i < 7; i = i + 1) begin: pp_row
            for (j = 0; j < 7; j = j + 1) begin: pp_col
                assign partial_products[i][j] = a[i] & b[j];
            end
            // 符号位列的处理
            assign partial_products[i][7] = ~(a[i] & b[7]);
        end
        
        // 符号位行的处理
        for (j = 0; j < 7; j = j + 1) begin: pp_sign_row
            assign partial_products[7][j] = ~(a[7] & b[j]);
        end
        
        // 符号位相乘
        assign partial_products[7][7] = a[7] & b[7];
    endgenerate
    
    // 部分积求和电路
    wire [14:0] carries;
    wire [7:0] sum_row0;
    wire [8:0] sum_row1;
    wire [9:0] sum_row2;
    wire [10:0] sum_row3;
    wire [11:0] sum_row4;
    wire [12:0] sum_row5;
    wire [13:0] sum_row6;
    wire [14:0] sum_row7;
    
    // 第一行部分积
    assign sum_row0 = {partial_products[0][7:0]};
    assign p[0] = sum_row0[0];
    
    // 累加各行部分积
    assign sum_row1 = {1'b1, partial_products[1][7:0]} + {sum_row0[7:1], 1'b0};
    assign p[1] = sum_row1[0];
    
    assign sum_row2 = {1'b1, partial_products[2][7:0], 1'b0} + {sum_row1[8:1], 1'b0};
    assign p[2] = sum_row2[0];
    
    assign sum_row3 = {1'b1, partial_products[3][7:0], 2'b0} + {sum_row2[9:1], 1'b0};
    assign p[3] = sum_row3[0];
    
    assign sum_row4 = {1'b1, partial_products[4][7:0], 3'b0} + {sum_row3[10:1], 1'b0};
    assign p[4] = sum_row4[0];
    
    assign sum_row5 = {1'b1, partial_products[5][7:0], 4'b0} + {sum_row4[11:1], 1'b0};
    assign p[5] = sum_row5[0];
    
    assign sum_row6 = {1'b1, partial_products[6][7:0], 5'b0} + {sum_row5[12:1], 1'b0};
    assign p[6] = sum_row6[0];
    
    // 最后一行部分积，需要加上Baugh-Wooley算法的修正常数1
    assign sum_row7 = {1'b1, partial_products[7][7:0], 6'b0} + {sum_row6[13:1], 1'b0} + 15'h0001;
    assign p[14:7] = sum_row7[7:0];
    assign p[15] = sum_row7[8];
    
endmodule