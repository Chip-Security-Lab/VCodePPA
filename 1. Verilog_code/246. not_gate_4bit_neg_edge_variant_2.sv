//SystemVerilog
module not_gate_4bit_neg_edge_pipelined (
    input wire clk,
    input wire [3:0] A,
    output reg [3:0] Y
);

    // Pipelined stages
    reg [3:0] Y_reg1; // Register after the inversion
    reg [3:0] Y_reg2; // Output stage register

    always @ (negedge clk) begin
        // Stage 1: Perform the inversion and register
        Y_reg1 <= ~A;

        // Stage 2: Register the result
        Y_reg2 <= Y_reg1;

        // Output stage: Register the final output
        Y <= Y_reg2;
    end

endmodule