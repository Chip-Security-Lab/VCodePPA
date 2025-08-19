//SystemVerilog
module Shift_AND_Top (
    input [2:0] shift_ctrl,
    input [31:0] vec,
    output [31:0] out
);
    // 内部连线
    wire [31:0] mask;
    
    // 子模块实例化
    Mask_Generator mask_gen (
        .shift_ctrl(shift_ctrl),
        .mask(mask)
    );
    
    Bitwise_AND bitwise_and (
        .vec(vec),
        .mask(mask),
        .result(out)
    );
    
endmodule

// 掩码生成子模块
module Mask_Generator (
    input [2:0] shift_ctrl,
    output reg [31:0] mask
);
    // 基于移位控制信号生成适当的掩码
    always @(*) begin
        case (shift_ctrl)
            3'd0: mask = 32'hFFFFFFFF;  // 无掩码（全部保留）
            3'd1: mask = 32'hFFFFFFFE;  // 移位1位对应的掩码
            3'd2: mask = 32'hFFFFFFFC;  // 移位2位对应的掩码
            3'd3: mask = 32'hFFFFFFF8;  // 移位3位对应的掩码
            3'd4: mask = 32'hFFFFFFF0;  // 移位4位对应的掩码
            3'd5: mask = 32'hFFFFFFE0;  // 移位5位对应的掩码
            3'd6: mask = 32'hFFFFFFC0;  // 移位6位对应的掩码
            3'd7: mask = 32'hFFFFFF80;  // 移位7位对应的掩码
            default: mask = 32'hFFFFFFFF;  // 默认无掩码
        endcase
    end
endmodule

// 按位与运算子模块
module Bitwise_AND (
    input [31:0] vec,
    input [31:0] mask,
    output [31:0] result
);
    // 执行按位与操作
    assign result = vec & mask;
endmodule