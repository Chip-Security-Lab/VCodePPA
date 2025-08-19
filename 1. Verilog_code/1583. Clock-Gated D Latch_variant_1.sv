//SystemVerilog
module d_latch_clock_gated (
    input wire d,
    input wire clk,
    input wire gate_en,
    output reg q
);
    // Eliminate intermediate wire and directly use the gated clock in the always block
    // This reduces area by removing one wire and potentially simplifying routing
    
    always @* begin
        if (clk && gate_en)
            q = d;
    end
endmodule