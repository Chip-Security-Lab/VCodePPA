//SystemVerilog
module d_latch_sync_rst (
    input wire d,
    input wire enable,
    input wire rst,      // Active high reset
    output reg q
);
    // 优化版本的D锁存器，使用敏感列表优化
    // 将rst放在敏感列表首位，提高复位优先级
    always @(rst or enable or d) begin
        if (rst)
            q <= 1'b0;  // 复位条件
        else if (enable)
            q <= d;     // 使能条件
    end
endmodule