//SystemVerilog
module dual_phase_clkgen(
    input wire sys_clk,
    input wire async_rst,
    output wire clk_0deg,
    output wire clk_180deg
);
    // 内部信号声明
    wire next_phase;         // 组合逻辑计算的下一相位
    wire next_phase_n;       // 组合逻辑计算的下一互补相位
    reg phase_register;      // 存储当前相位的寄存器
    reg phase_register_n;    // 存储当前互补相位的寄存器
    
    // 组合逻辑部分 - 计算下一状态
    assign next_phase = ~phase_register;
    assign next_phase_n = ~phase_register_n;
    
    // 时序逻辑部分 - 合并具有相同触发条件的always块
    always @(posedge sys_clk or posedge async_rst) begin
        if (async_rst) begin
            phase_register <= 1'b0;
            phase_register_n <= 1'b1;
        end else begin
            phase_register <= next_phase;
            phase_register_n <= next_phase_n;
        end
    end
    
    // 输出赋值
    assign clk_0deg = phase_register;
    assign clk_180deg = phase_register_n;
    
endmodule