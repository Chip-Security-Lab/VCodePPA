module async_divider (
    input wire master_clk,
    output wire div2_clk,
    output wire div4_clk,
    output wire div8_clk
);
    reg [2:0] div_chain;
    
    always @(posedge master_clk)
        div_chain[0] <= ~div_chain[0];
        
    always @(posedge div_chain[0])
        div_chain[1] <= ~div_chain[1];
        
    always @(posedge div_chain[1])
        div_chain[2] <= ~div_chain[2];
    
    assign div2_clk = div_chain[0];
    assign div4_clk = div_chain[1];
    assign div8_clk = div_chain[2];
endmodule