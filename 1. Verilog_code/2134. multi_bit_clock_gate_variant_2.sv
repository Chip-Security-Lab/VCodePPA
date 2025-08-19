//SystemVerilog
// Top-level module
module multi_bit_clock_gate #(
    parameter WIDTH = 4
) (
    input  wire clk_in,
    input  wire [WIDTH-1:0] enable_vector,
    output wire [WIDTH-1:0] clk_out
);
    // Instantiate individual clock gate cells for each bit
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gate_gen
            single_bit_clock_gate u_clock_gate (
                .clk_in(clk_in),
                .enable(enable_vector[i]),
                .clk_out(clk_out[i])
            );
        end
    endgenerate
endmodule

// Single-bit clock gate sub-module
module single_bit_clock_gate (
    input  wire clk_in,
    input  wire enable,
    output wire clk_out
);
    // Clock gating logic
    assign clk_out = clk_in & enable;
endmodule