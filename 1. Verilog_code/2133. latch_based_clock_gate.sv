module latch_based_clock_gate (
    input  wire clk_in,
    input  wire enable,
    output wire clk_out
);
    reg latch_out;
    
    always @(*) begin
        if (!clk_in)
            latch_out <= enable;
    end
    
    assign clk_out = clk_in & latch_out;
endmodule