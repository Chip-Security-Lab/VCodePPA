//SystemVerilog
module hybrid_shifter #(
    parameter DATA_W = 16,
    parameter SHIFT_W = 4
)(
    input [DATA_W-1:0] din,
    input [SHIFT_W-1:0] shift,
    input dir,  // 0-left, 1-right
    input mode,  // 0-logical, 1-arithmetic
    output [DATA_W-1:0] dout
);
    // 内部信号定义
    wire [DATA_W-1:0] left_shift_result;
    wire [DATA_W-1:0] right_shift_logical;
    wire [DATA_W-1:0] right_shift_arithmetic;
    wire [DATA_W-1:0] right_shift_result;
    
    // 左移桶形移位器实现
    wire [DATA_W-1:0] left_stage_in [SHIFT_W:0];
    assign left_stage_in[0] = din;
    
    genvar i;
    generate
        for (i = 0; i < SHIFT_W; i = i + 1) begin : left_barrel_stages
            assign left_stage_in[i+1] = shift[i] ? {left_stage_in[i][DATA_W-(2**i)-1:0], {(2**i){1'b0}}} : left_stage_in[i];
        end
    endgenerate
    
    assign left_shift_result = left_stage_in[SHIFT_W];
    
    // 右移逻辑移位桶形移位器实现
    wire [DATA_W-1:0] right_logical_stage_in [SHIFT_W:0];
    assign right_logical_stage_in[0] = din;
    
    generate
        for (i = 0; i < SHIFT_W; i = i + 1) begin : right_logical_barrel_stages
            assign right_logical_stage_in[i+1] = shift[i] ? {{(2**i){1'b0}}, right_logical_stage_in[i][DATA_W-1:(2**i)]} : right_logical_stage_in[i];
        end
    endgenerate
    
    assign right_shift_logical = right_logical_stage_in[SHIFT_W];
    
    // 右移算术移位桶形移位器实现
    wire [DATA_W-1:0] right_arithmetic_stage_in [SHIFT_W:0];
    assign right_arithmetic_stage_in[0] = din;
    
    generate
        for (i = 0; i < SHIFT_W; i = i + 1) begin : right_arithmetic_barrel_stages
            assign right_arithmetic_stage_in[i+1] = shift[i] ? {{(2**i){din[DATA_W-1]}}, right_arithmetic_stage_in[i][DATA_W-1:(2**i)]} : right_arithmetic_stage_in[i];
        end
    endgenerate
    
    assign right_shift_arithmetic = right_arithmetic_stage_in[SHIFT_W];
    
    // 选择正确的右移结果
    assign right_shift_result = mode ? right_shift_arithmetic : right_shift_logical;
    
    // 根据方向选择最终结果
    assign dout = dir ? right_shift_result : left_shift_result;
    
endmodule