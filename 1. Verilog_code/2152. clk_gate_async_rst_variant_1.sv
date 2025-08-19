//SystemVerilog
module clk_gate_async_rst #(parameter INIT=0) (
    input clk, rst_n, en,
    output reg q
);
    // 应用前向寄存器重定时技术后的流水线结构
    // 直接处理使能信号，减少输入到第一级寄存器的延迟
    wire en_wire;
    reg toggle_stage;
    
    // 将en信号直接连接到组合逻辑而非先通过寄存器
    assign en_wire = en;
    
    // 重定时后的流水线：直接生成toggle信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            toggle_stage <= 1'b0;
        else
            toggle_stage <= en_wire ? 1'b1 : 1'b0;
    end
    
    // 输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= INIT;
        else if (toggle_stage)
            q <= ~q;   // 有toggle，翻转输出
    end
endmodule