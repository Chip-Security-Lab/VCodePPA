module dual_edge_d_latch (
    input wire d,
    input wire clk,
    output reg q
);
    reg last_clk;
    
    always @* begin
        if (clk != last_clk)
            q = d;
        last_clk = clk;
    end
endmodule
