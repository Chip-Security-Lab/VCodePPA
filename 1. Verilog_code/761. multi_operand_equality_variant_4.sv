//SystemVerilog
module multi_operand_equality #(
    parameter OPERAND_WIDTH = 4,
    parameter NUM_OPERANDS = 4
)(
    input [OPERAND_WIDTH-1:0] operands [0:NUM_OPERANDS-1],
    output all_equal,
    output any_equal,
    output [NUM_OPERANDS-1:0] match_mask
);
    // 优化1: 简化match_with_first生成逻辑
    reg [NUM_OPERANDS-1:0] match_with_first;
    
    integer i;
    always @(*) begin
        match_with_first[0] = 1'b1; // 第一个操作数总是等于自己
        for (i = 1; i < NUM_OPERANDS; i = i + 1) begin
            match_with_first[i] = (operands[i] == operands[0]);
        end
    end
    
    // 优化2: 提前计算all_equal以用于any_equal
    assign all_equal = &match_with_first;
    
    // 优化3: 重写任何相等性检测逻辑，避免生成所有可能的对
    reg any_pairs_equal;
    integer j, k;
    
    always @(*) begin
        any_pairs_equal = 1'b0;
        for (j = 0; j < NUM_OPERANDS-1; j = j + 1) begin
            for (k = j + 1; k < NUM_OPERANDS; k = k + 1) begin
                // 使用短路逻辑提前退出
                if (operands[j] == operands[k]) begin
                    any_pairs_equal = 1'b1;
                end
            end
        end
    end
    
    // 优化4: all_equal为true时，any_equal必定为true，优化逻辑表达式
    assign any_equal = all_equal || any_pairs_equal;
    
    // 输出匹配掩码
    assign match_mask = match_with_first;
endmodule