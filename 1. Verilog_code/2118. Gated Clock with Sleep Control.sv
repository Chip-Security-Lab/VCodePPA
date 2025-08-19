module gated_clk_sleep(
    input clk_src,
    input sleep,
    input enable,
    output gated_clk
);
    reg enable_latch;
    
    // Latch enable signal on negative edge
    always @(negedge clk_src or posedge sleep) begin
        if (sleep)
            enable_latch <= 1'b0;
        else
            enable_latch <= enable;
    end
    
    // Gate the clock
    assign gated_clk = clk_src & enable_latch & ~sleep;
endmodule