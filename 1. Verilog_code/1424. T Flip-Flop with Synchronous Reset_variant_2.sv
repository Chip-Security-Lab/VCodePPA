//SystemVerilog
module t_ff_sync_reset (
    input wire clock,
    input wire reset,
    input wire toggle,
    output reg q_out
);
    // 寄存器重定时：将逻辑移到寄存器之前
    reg toggle_reg;
    
    // 捕获输入信号
    always @(posedge clock) begin
        if (reset)
            toggle_reg <= 1'b0;
        else
            toggle_reg <= toggle;
    end
    
    // 主状态逻辑
    always @(posedge clock) begin
        if (reset)
            q_out <= 1'b0;
        else if (toggle_reg)
            q_out <= ~q_out;
    end
endmodule