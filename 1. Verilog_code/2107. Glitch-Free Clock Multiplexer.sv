module glitch_free_clk_mux(
    input clk_a,
    input clk_b,
    input select,  // 0 for clk_a, 1 for clk_b
    input rst,
    output clk_out
);
    reg select_a, select_b;
    
    always @(negedge clk_a or posedge rst)
        if (rst) select_a <= 1'b0;
        else select_a <= ~select & ~select_b;
    
    always @(negedge clk_b or posedge rst)
        if (rst) select_b <= 1'b0;
        else select_b <= select & ~select_a;
    
    assign clk_out = (clk_a & select_a) | (clk_b & select_b);
endmodule