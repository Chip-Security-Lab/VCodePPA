//SystemVerilog
module hybrid_shifter #(
    parameter DATA_W = 16,
    parameter SHIFT_W = 4
)(
    input [DATA_W-1:0] din,
    input [SHIFT_W-1:0] shift,
    input dir,  // 0-left, 1-right
    input mode,  // 0-logical, 1-arithmetic
    output reg [DATA_W-1:0] dout
);
    // 左移桶形移位器实现
    wire [DATA_W-1:0] left_shift_stage[SHIFT_W:0];
    
    // 右移桶形移位器实现
    wire [DATA_W-1:0] right_logical_stage[SHIFT_W:0];
    wire [DATA_W-1:0] right_arith_stage[SHIFT_W:0];
    
    // 初始输入
    assign left_shift_stage[0] = din;
    assign right_logical_stage[0] = din;
    assign right_arith_stage[0] = din;
    
    // 生成桶形移位器的各个阶段
    genvar i;
    generate
        for (i = 0; i < SHIFT_W; i = i + 1) begin: BARREL_STAGES
            // 左移桶形移位器阶段
            assign left_shift_stage[i+1] = shift[i] ? 
                {left_shift_stage[i][DATA_W-1-(2**i):0], {(2**i){1'b0}}} : 
                left_shift_stage[i];
            
            // 右逻辑移位桶形移位器阶段
            assign right_logical_stage[i+1] = shift[i] ? 
                {{(2**i){1'b0}}, right_logical_stage[i][DATA_W-1:(2**i)]} : 
                right_logical_stage[i];
            
            // 右算术移位桶形移位器阶段
            assign right_arith_stage[i+1] = shift[i] ? 
                {{(2**i){right_arith_stage[i][DATA_W-1]}}, right_arith_stage[i][DATA_W-1:(2**i)]} : 
                right_arith_stage[i];
        end
    endgenerate
    
    // 输出多路复用器
    always @(*) begin
        if (dir) begin  // 右移
            if (mode)  // 算术右移
                dout = right_arith_stage[SHIFT_W];
            else  // 逻辑右移
                dout = right_logical_stage[SHIFT_W];
        end else begin  // 左移
            dout = left_shift_stage[SHIFT_W];
        end
    end
    
endmodule