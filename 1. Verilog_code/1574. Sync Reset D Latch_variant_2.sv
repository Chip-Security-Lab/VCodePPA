//SystemVerilog
module d_latch_sync_rst (
    input wire d,
    input wire enable,
    input wire rst,      // Active high reset
    output reg q
);
    // 优化实现：使用case语句替代if-else级联结构
    always @* begin
        case ({rst, enable})
            2'b10, 
            2'b11: q <= 1'b0;  // 当复位有效时，无条件复位
            2'b01: q <= d;     // 使能有效且非复位状态下更新输出
            2'b00: q <= q;     // 保持当前值
        endcase
    end
endmodule