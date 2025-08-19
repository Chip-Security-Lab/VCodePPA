//SystemVerilog
module not_gate_4bit_neg_edge_pipeline (
    input wire clk,
    input wire [3:0] A,
    output reg [3:0] Y
);

    // Stage 1: Perform the negation directly on the input
    wire [3:0] Y_comb;
    assign Y_comb = ~A;

    // Stage 2: Register the result of the negation on the falling edge of the clock
    // The register originally after the negation is moved forward to capture the result
    // of the combination logic directly from the input.
    always @ (negedge clk) begin
        Y <= Y_comb;
    end

endmodule