//SystemVerilog
// 顶层模块
module Hybrid_AND(
    input [1:0] ctrl,
    input [7:0] base,
    output [7:0] result
);
    // 内部连线
    wire [7:0] mask;
    
    // 子模块实例化
    MaskGenerator mask_gen (
        .ctrl(ctrl),
        .mask(mask)
    );
    
    BitMasking bit_mask (
        .base(base),
        .mask(mask),
        .result(result)
    );
endmodule

// 子模块：掩码生成器
module MaskGenerator(
    input [1:0] ctrl,
    output [7:0] mask
);
    // 根据控制信号生成掩码
    // 对应原来的 (8'h0F << (ctrl * 4))
    reg [7:0] mask_reg;
    
    always @(*) begin
        case(ctrl)
            2'b00: mask_reg = 8'h0F; // 0000_1111
            2'b01: mask_reg = 8'hF0; // 1111_0000
            2'b10: mask_reg = 8'h00; // 0000_0000 (溢出情况)
            2'b11: mask_reg = 8'h00; // 0000_0000 (溢出情况)
            default: mask_reg = 8'h0F;
        endcase
    end
    
    assign mask = mask_reg;
endmodule

// 子模块：位掩码操作
module BitMasking(
    input [7:0] base,
    input [7:0] mask,
    output [7:0] result
);
    // 执行位掩码与操作
    assign result = base & mask;
endmodule