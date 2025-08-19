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
    // 左移桶形移位器逻辑
    reg [DATA_W-1:0] left_shift_stage[SHIFT_W:0];
    
    // 右移桶形移位器逻辑
    reg [DATA_W-1:0] right_shift_stage[SHIFT_W:0];
    
    // 初始输入
    always @(*) begin
        left_shift_stage[0] = din;
        right_shift_stage[0] = din;
    end
    
    // 通过级联方式实现桶形移位器
    genvar i;
    generate
        for (i = 0; i < SHIFT_W; i = i + 1) begin : shift_stages
            // 左移桶形移位器
            always @(*) begin
                if (shift[i])
                    left_shift_stage[i+1] = left_shift_stage[i] << (1 << i);
                else
                    left_shift_stage[i+1] = left_shift_stage[i];
            end
            
            // 右移桶形移位器 - 根据模式选择算术或逻辑右移
            always @(*) begin
                if (shift[i]) begin
                    if (mode) begin
                        // 算术右移 - 保持符号位
                        right_shift_stage[i+1] = {
                            {(1<<i){din[DATA_W-1] & mode}},
                            right_shift_stage[i][DATA_W-1:(1<<i)]
                        };
                    end else begin
                        // 逻辑右移 - 用0填充
                        right_shift_stage[i+1] = {
                            {(1<<i){1'b0}},
                            right_shift_stage[i][DATA_W-1:(1<<i)]
                        };
                    end
                end else begin
                    right_shift_stage[i+1] = right_shift_stage[i];
                end
            end
        end
    endgenerate
    
    // 根据方向选择最终输出
    assign dout = dir ? right_shift_stage[SHIFT_W] : left_shift_stage[SHIFT_W];

endmodule