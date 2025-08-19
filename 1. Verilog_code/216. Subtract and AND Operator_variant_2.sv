//SystemVerilog
module shift_xor_operator (
    input [7:0] a,
    input [2:0] shift_amount,
    output reg [7:0] shifted_result,
    output [7:0] xor_result
);
    reg [7:0] stage1_out;
    reg [7:0] stage2_out;
    reg [7:0] stage3_out;
    
    // 第一级: 移动1位或不移动
    always @(*) begin
        if (shift_amount[0]) begin
            stage1_out = {1'b0, a[7:1]};
        end else begin
            stage1_out = a;
        end
    end
    
    // 第二级: 移动2位或不移动
    always @(*) begin
        if (shift_amount[1]) begin
            stage2_out = {2'b00, stage1_out[7:2]};
        end else begin
            stage2_out = stage1_out;
        end
    end
    
    // 第三级: 移动4位或不移动
    always @(*) begin
        if (shift_amount[2]) begin
            stage3_out = {4'b0000, stage2_out[7:4]};
        end else begin
            stage3_out = stage2_out;
        end
    end
    
    // 最终右移结果
    always @(*) begin
        shifted_result = stage3_out;
    end
    
    // 异或操作保持不变
    assign xor_result = a ^ shifted_result;
endmodule