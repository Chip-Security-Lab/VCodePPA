//SystemVerilog
module clk_gate_pipeline #(parameter STAGES=3) (
    input clk, en, in,
    output reg out
);
    reg [STAGES-1:0] pipe;
    reg en_latch;
    
    // 时钟门控优化 - 使用非阻塞赋值确保正确的锁存行为
    always @(negedge clk) begin
        en_latch <= en;
    end
    
    wire gated_clk = clk & en_latch;
    
    // 管道寄存器更新
    always @(posedge gated_clk) begin
        pipe <= {pipe[STAGES-2:0], in};
    end
    
    // 输出寄存器更新
    always @(posedge clk) begin
        out <= pipe[STAGES-1];
    end
endmodule