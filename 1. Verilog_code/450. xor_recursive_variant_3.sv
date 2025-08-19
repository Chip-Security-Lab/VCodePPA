//SystemVerilog
module xor_recursive(
    input [7:0] a, 
    input [7:0] b, 
    output [7:0] y
);
    // 阶段1: 计算按位异或
    wire [7:0] ab_xor;
    bit_xor_stage bit_xor_inst (
        .a(a),
        .b(b),
        .ab_xor(ab_xor)
    );
    
    // 阶段2: 计算级联异或
    cascade_xor_stage cascade_xor_inst (
        .ab_xor(ab_xor),
        .y(y)
    );
endmodule

// 阶段1: 按位异或计算模块
module bit_xor_stage(
    input [7:0] a,
    input [7:0] b,
    output [7:0] ab_xor
);
    // 并行计算每个位的异或结果
    assign ab_xor = a ^ b;
endmodule

// 阶段2: 级联异或计算模块
module cascade_xor_stage(
    input [7:0] ab_xor,
    output [7:0] y
);
    // 中间结果缓存以减少重复计算，提高PPA指标
    wire [7:0] intermediate;
    
    // 使用参数化设计的子模块计算每一位的级联异或
    cascade_bit_calculator bit0_calc (
        .xor_in(ab_xor[0:0]),
        .cascade_in(1'b0),
        .y(y[0]),
        .intermediate(intermediate[0])
    );
    
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : gen_cascade_bits
            cascade_bit_calculator bit_calc (
                .xor_in(ab_xor[i:i]),
                .cascade_in(intermediate[i-1]),
                .y(y[i]),
                .intermediate(intermediate[i])
            );
        end
    endgenerate
endmodule

// 单比特级联异或计算器
module cascade_bit_calculator(
    input [0:0] xor_in,
    input cascade_in,
    output y,
    output intermediate
);
    // 计算当前位的级联异或结果
    assign intermediate = xor_in[0] ^ cascade_in;
    assign y = intermediate;
endmodule