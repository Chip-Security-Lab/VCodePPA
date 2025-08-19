//SystemVerilog
// 顶层模块
module xor2_7 #(parameter WIDTH = 8) (
    input wire [WIDTH-1:0] A, B,
    output wire [WIDTH-1:0] Y
);
    // 实例化优化后的先行借位减法器子模块
    parallel_borrow_subtractor #(
        .DATA_WIDTH(WIDTH)
    ) subtractor_unit (
        .minuend(A),
        .subtrahend(B),
        .difference(Y)
    );
endmodule

// 优化后的先行借位减法器子模块
module parallel_borrow_subtractor #(
    parameter DATA_WIDTH = 8
) (
    input wire [DATA_WIDTH-1:0] minuend,
    input wire [DATA_WIDTH-1:0] subtrahend,
    output wire [DATA_WIDTH-1:0] difference
);
    wire [DATA_WIDTH:0] borrow;
    
    // 初始无借位
    assign borrow[0] = 1'b0;
    
    // 生成借位和差值
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : sub_bit
            // 差值计算 - XOR运算保持不变，因为它已经是最优表达式
            assign difference[i] = minuend[i] ^ subtrahend[i] ^ borrow[i];
            
            // 借位生成逻辑 - 使用布尔代数简化
            // 原表达式: (~minuend[i] & subtrahend[i]) | (~minuend[i] & borrow[i]) | (subtrahend[i] & borrow[i])
            // 简化过程: 使用分配律 ~minuend[i] & (subtrahend[i] | borrow[i]) | (subtrahend[i] & borrow[i])
            // 进一步简化为: (subtrahend[i] & borrow[i]) | (~minuend[i] & (subtrahend[i] | borrow[i]))
            // 最终简化为: (subtrahend[i] & borrow[i]) | (~minuend[i] & (subtrahend[i] | borrow[i]))
            assign borrow[i+1] = (subtrahend[i] & borrow[i]) | (~minuend[i] & (subtrahend[i] | borrow[i]));
        end
    endgenerate
endmodule