//SystemVerilog
// Hierarchical, modularized, and optimized version of AlwaysNorMul8
module AlwaysNorMul8 (
    input  signed [7:0] a,
    input  signed [7:0] b,
    output reg  [15:0] y
);
    wire [15:0] mul_result;

    BaughWooleyMul8x8 u_baugh_wooley (
        .a(a),
        .b(b),
        .product(mul_result)
    );

    always @(*) begin
        y = mul_result;
    end
endmodule

// Top-level 8x8 Baugh-Wooley Multiplier with hierarchical structure
module BaughWooleyMul8x8 (
    input  signed [7:0] a,
    input  signed [7:0] b,
    output [15:0] product
);
    wire [15:0] partial_products [7:0];
    wire [15:0] bw_partial_products [7:0];
    wire [15:0] correction;
    wire [15:0] sum_stage1 [3:0];
    wire [15:0] sum_stage2 [1:0];
    wire [15:0] sum_stage3;

    // Generate Partial Products
    BWPartialProductGen u_ppgen (
        .a(a),
        .b(b),
        .partial_products(partial_products)
    );

    // Baugh-Wooley Partial Product Correction
    BWBaughWooleyPP u_bwpp (
        .a(a),
        .b(b),
        .bw_partial_products(bw_partial_products)
    );

    // Correction Terms
    BaughWooleyCorrection u_bwcorrection (
        .a(a),
        .b(b),
        .correction(correction)
    );

    // Partial Product Adder Tree
    BWAdderTree u_adder_tree (
        .bw_partial_products(bw_partial_products),
        .sum_stage1(sum_stage1),
        .sum_stage2(sum_stage2),
        .sum_stage3(sum_stage3)
    );

    // Final Product Calculation
    assign product = sum_stage3 + correction;
endmodule

//------------------------------------------------------------------------------
// 子模块：BWPartialProductGen
// 功能：根据输入a和b生成8个移位的部分积（无符号）
//------------------------------------------------------------------------------
module BWPartialProductGen (
    input  signed [7:0] a,
    input  signed [7:0] b,
    output [15:0] partial_products [7:0]
);
    genvar i;
    generate
        for (i=0; i<8; i=i+1) begin : PARTIALS
            assign partial_products[i] = {{8{1'b0}}, (a[i] ? b : 8'b0)} << i;
        end
    endgenerate
endmodule

//------------------------------------------------------------------------------
// 子模块：BWBaughWooleyPP
// 功能：生成Baugh-Wooley算法所需的符号扩展和补偿后的部分积
//------------------------------------------------------------------------------
module BWBaughWooleyPP (
    input  signed [7:0] a,
    input  signed [7:0] b,
    output [15:0] bw_partial_products [7:0]
);
    genvar i;
    generate
        for (i=0; i<7; i=i+1) begin : BW_PP
            assign bw_partial_products[i] = {8'b0, a[i] ? b : 8'b0} << i;
        end
        assign bw_partial_products[7] = {8'b0, (a[7] ? b : 8'b0)} << 7;
    endgenerate
endmodule

//------------------------------------------------------------------------------
// 子模块：BaughWooleyCorrection
// 功能：生成Baugh-Wooley乘法器的最终补偿项
//------------------------------------------------------------------------------
module BaughWooleyCorrection (
    input  signed [7:0] a,
    input  signed [7:0] b,
    output [15:0] correction
);
    wire msb_and;
    assign msb_and = a[7] & b[7];
    assign correction = { {(8){msb_and}}, 8'b0 } + 
                        { {(7){msb_and}}, 9'b0 } + 
                        { {(7){msb_and}}, 1'b0, 8'b0 };
endmodule

//------------------------------------------------------------------------------
// 子模块：BWAdderTree
// 功能：将8个Baugh-Wooley部分积通过加法树方式归约为最终的和
//------------------------------------------------------------------------------
module BWAdderTree (
    input  [15:0] bw_partial_products [7:0],
    output [15:0] sum_stage1 [3:0],
    output [15:0] sum_stage2 [1:0],
    output [15:0] sum_stage3
);
    // 第一层加法
    assign sum_stage1[0] = bw_partial_products[0] + bw_partial_products[1];
    assign sum_stage1[1] = bw_partial_products[2] + bw_partial_products[3];
    assign sum_stage1[2] = bw_partial_products[4] + bw_partial_products[5];
    assign sum_stage1[3] = bw_partial_products[6] + bw_partial_products[7];

    // 第二层加法
    assign sum_stage2[0] = sum_stage1[0] + sum_stage1[1];
    assign sum_stage2[1] = sum_stage1[2] + sum_stage1[3];

    // 第三层加法
    assign sum_stage3 = sum_stage2[0] + sum_stage2[1];
endmodule