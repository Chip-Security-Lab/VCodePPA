//SystemVerilog
module decoder_async #(parameter AW=4, DW=16) (
    input [AW-1:0] addr,
    output reg [DW-1:0] decoded
);
    
    wire valid_addr = (addr < DW);
    
    // 桶形移位器实现
    // 第一级移位 - 移动0或1位
    wire [DW-1:0] shift_stage1;
    assign shift_stage1 = addr[0] ? {1'b0, 1'b1, {(DW-2){1'b0}}} : {1'b1, {(DW-1){1'b0}}};
    
    // 第二级移位 - 移动0或2位
    wire [DW-1:0] shift_stage2;
    assign shift_stage2 = addr[1] ? {2'b00, shift_stage1[DW-1:2]} : shift_stage1;
    
    // 第三级移位 - 移动0或4位
    wire [DW-1:0] shift_stage3;
    assign shift_stage3 = addr[2] ? {4'b0000, shift_stage2[DW-1:4]} : shift_stage2;
    
    // 第四级移位 - 移动0或8位
    wire [DW-1:0] shift_stage4;
    generate
        if (AW > 3) begin
            assign shift_stage4 = addr[3] ? {8'b0, shift_stage3[DW-1:8]} : shift_stage3;
        end else begin
            assign shift_stage4 = shift_stage3;
        end
    endgenerate
    
    // 输出结果
    always @(*) begin
        decoded = valid_addr ? shift_stage4 : {DW{1'b0}};
    end
    
endmodule