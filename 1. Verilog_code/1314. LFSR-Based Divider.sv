module lfsr_divider (
    input i_clk, i_rst,
    output o_clk_div
);
    reg [4:0] lfsr;
    wire feedback = lfsr[4] ^ lfsr[2];
    
    always @(posedge i_clk) begin
        if (i_rst)
            lfsr <= 5'h1f;
        else
            lfsr <= {lfsr[3:0], feedback};
    end
    
    assign o_clk_div = lfsr[4];
endmodule