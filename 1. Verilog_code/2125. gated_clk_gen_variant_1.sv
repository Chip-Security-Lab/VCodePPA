//SystemVerilog
module gated_clk_gen(
    input wire main_clk,
    input wire gate_en,
    output reg gated_clk
);
    reg latch_en;
    wire gated_clk_comb;
    
    // 使用latch以防止毛刺
    always @(negedge main_clk) begin
        latch_en <= gate_en;
    end
    
    // 组合逻辑部分
    assign gated_clk_comb = main_clk & latch_en;
    
    // 将输出寄存器后移，放置在组合逻辑之后
    always @(posedge main_clk or negedge latch_en) begin
        if (!latch_en)
            gated_clk <= 1'b0;
        else
            gated_clk <= gated_clk_comb;
    end
endmodule