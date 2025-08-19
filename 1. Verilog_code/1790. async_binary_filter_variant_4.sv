//SystemVerilog
module async_binary_filter #(
    parameter W = 8
)(
    input [W-1:0] analog_in,
    input [W-1:0] threshold,
    output binary_out
);
    wire [W-1:0] difference;
    wire borrow_out;
    
    // 使用先行借位减法器实现
    parallel_borrow_subtractor #(
        .WIDTH(W)
    ) subtractor (
        .minuend(analog_in),
        .subtrahend(threshold),
        .difference(difference),
        .borrow_out(borrow_out)
    );
    
    // 当没有借位输出时，表示 analog_in >= threshold
    assign binary_out = ~borrow_out;
endmodule

module parallel_borrow_subtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] difference,
    output borrow_out
);
    wire [WIDTH:0] borrow;
    assign borrow[0] = 1'b0;
    
    // 计算每一位的借位和差值
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_borrow
            // 优化后的借位信号计算，使用德摩根定律和布尔代数简化
            // 原式: (~minuend[i] & subtrahend[i]) | (~minuend[i] & borrow[i]) | (subtrahend[i] & borrow[i])
            // 提取公因子: ~minuend[i] & (subtrahend[i] | borrow[i]) | (subtrahend[i] & borrow[i])
            // 进一步简化: ~minuend[i] & (subtrahend[i] | borrow[i]) | (subtrahend[i] & borrow[i])
            assign borrow[i+1] = (~minuend[i] & (subtrahend[i] | borrow[i])) | (subtrahend[i] & borrow[i]);
            
            // 计算差值
            assign difference[i] = minuend[i] ^ subtrahend[i] ^ borrow[i];
        end
    endgenerate
    
    // 最终借位输出
    assign borrow_out = borrow[WIDTH];
endmodule