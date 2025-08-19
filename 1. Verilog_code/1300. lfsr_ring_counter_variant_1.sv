//SystemVerilog
module lfsr_ring_counter (
    input  wire       clk,     // 时钟信号
    input  wire       valid,   // 数据有效信号
    output wire       ready,   // 准备接收信号
    output reg  [3:0] lfsr_reg // LFSR寄存器输出
);

    // 优化内部信号定义
    reg  ready_r;
    
    // 反馈逻辑 - 直接使用位选择
    wire feedback = lfsr_reg[0];
    
    // 优化准备信号逻辑，降低时序路径复杂度
    always @(posedge clk) begin
        ready_r <= ~(valid & ready_r);
    end
    
    // 优化LFSR逻辑，消除组合逻辑依赖
    always @(posedge clk) begin
        if (valid & ready_r)
            lfsr_reg <= {feedback, lfsr_reg[3:1]};
        else if (~valid)
            lfsr_reg <= 4'b0001;
    end
    
    // 准备好信号直接使用寄存器输出，减少组合逻辑延迟
    assign ready = ready_r;

endmodule