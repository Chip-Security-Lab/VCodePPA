module ring_oscillator(
    input enable,
    output clk_out
);
    wire [4:0] chain;
    
    assign chain[0] = enable ? ~chain[4] : 1'b0;
    assign chain[1] = ~chain[0];
    assign chain[2] = ~chain[1];
    assign chain[3] = ~chain[2];
    assign chain[4] = ~chain[3];
    assign clk_out = chain[4];
endmodule