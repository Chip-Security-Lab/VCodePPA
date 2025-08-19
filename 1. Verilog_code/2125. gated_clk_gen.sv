module gated_clk_gen(
    input main_clk,
    input gate_en,
    output gated_clk
);
    reg latch_en;
    
    // 使用latch以防止毛刺
    always @(*) begin
        if (!main_clk)
            latch_en = gate_en;
    end
    
    assign gated_clk = main_clk & latch_en;
endmodule