module d_latch_clock_gated (
    input wire d,
    input wire clk,
    input wire gate_en,
    output reg q
);
    wire gated_enable;
    
    assign gated_enable = clk && gate_en;
    
    always @* begin
        if (gated_enable)
            q = d;
    end
endmodule