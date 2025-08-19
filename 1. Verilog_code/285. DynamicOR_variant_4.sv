//SystemVerilog
module DynamicOR(
    input [2:0] shift,
    input [31:0] vec1, vec2,
    output reg [31:0] res
);
    reg [31:0] shift_stage0;
    reg [31:0] shift_stage1;
    reg [31:0] shift_stage2;
    reg [31:0] shifted_vec1;
    
    // 使用组合逻辑实现桶形移位器
    always @(*) begin
        // 第一级移位 - 移动0或1位
        if (shift[0]) begin
            shift_stage0 = {vec1[30:0], 1'b0};
        end else begin
            shift_stage0 = vec1;
        end
        
        // 第二级移位 - 移动0或2位
        if (shift[1]) begin
            shift_stage1 = {shift_stage0[29:0], 2'b00};
        end else begin
            shift_stage1 = shift_stage0;
        end
        
        // 第三级移位 - 移动0或4位
        if (shift[2]) begin
            shift_stage2 = {shift_stage1[27:0], 4'b0000};
        end else begin
            shift_stage2 = shift_stage1;
        end
        
        // 最终移位结果
        shifted_vec1 = shift_stage2;
        
        // 按位或操作
        res = shifted_vec1 | vec2;
    end
endmodule