module multi_bit_clock_gate #(
    parameter WIDTH = 4
) (
    input  wire clk_in,
    input  wire [WIDTH-1:0] enable_vector,
    output wire [WIDTH-1:0] clk_out
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gate_gen
            assign clk_out[i] = clk_in & enable_vector[i];
        end
    endgenerate
endmodule