//SystemVerilog
// 顶层模块
module edge_pulse_gen (
    input      clk,
    input      signal_in,
    output     pulse_out
);
    // 内部寄存器
    reg signal_delayed;
    reg pulse_reg;
    
    // 实现边沿检测并注册输出
    always @(posedge clk) begin
        signal_delayed <= signal_in;
        pulse_reg <= signal_in & ~signal_delayed;
    end
    
    // 使用注册输出减少组合逻辑路径延迟
    assign pulse_out = pulse_reg;
    
endmodule