//SystemVerilog
// 顶层模块 - 比较器
module Comparator_BitwiseXOR #(parameter WIDTH = 16) (
    input  [WIDTH-1:0] vec_a,
    input  [WIDTH-1:0] vec_b,
    output             not_equal
);
    wire [WIDTH-1:0] diff_bits;   // 差异位标识
    
    // 实例化位差异检测子模块
    BitDifferenceDetector #(
        .WIDTH(WIDTH)
    ) diff_detector (
        .vec_a(vec_a),
        .vec_b(vec_b),
        .diff_bits(diff_bits)
    );
    
    // 实例化结果归约子模块
    DifferenceReducer #(
        .WIDTH(WIDTH)
    ) reducer (
        .diff_bits(diff_bits),
        .result(not_equal)
    );
endmodule

// 子模块1: 位差异检测器 - 使用借位减法算法实现
module BitDifferenceDetector #(parameter WIDTH = 16) (
    input  [WIDTH-1:0] vec_a,
    input  [WIDTH-1:0] vec_b,
    output [WIDTH-1:0] diff_bits
);
    wire [WIDTH:0] borrow;      // 借位信号，额外多一位
    wire [WIDTH-1:0] diff;      // 差值结果
    
    // 初始无借位
    assign borrow[0] = 1'b0;
    
    // 采用借位减法算法实现
    genvar i;
    generate
        for (i=0; i<WIDTH; i=i+1) begin : BORROW_SUB
            // 差值计算: diff = a ^ b ^ borrow_in
            assign diff[i] = vec_a[i] ^ vec_b[i] ^ borrow[i];
            
            // 借位生成: borrow_out = (~a & b) | (~a & borrow_in) | (b & borrow_in)
            assign borrow[i+1] = (~vec_a[i] & vec_b[i]) | (~vec_a[i] & borrow[i]) | (vec_b[i] & borrow[i]);
        end
    endgenerate
    
    // 位差异检测结果
    assign diff_bits = diff ^ {WIDTH{borrow[WIDTH]}};
endmodule

// 子模块2: 差异归约器 - 使用平衡树结构优化
module DifferenceReducer #(parameter WIDTH = 16) (
    input  [WIDTH-1:0] diff_bits,
    output             result
);
    // 使用平衡树结构实现或运算，提高性能
    generate
        if (WIDTH == 1) begin
            // 单位情况
            assign result = diff_bits[0];
        end else if (WIDTH <= 4) begin
            // 小位宽直接或运算
            assign result = |diff_bits;
        end else begin
            // 大位宽使用分层归约
            wire left_result, right_result;
            localparam HALF = WIDTH/2;
            
            assign left_result = |diff_bits[WIDTH-1:HALF];
            assign right_result = |diff_bits[HALF-1:0];
            assign result = left_result | right_result;
        end
    endgenerate
endmodule