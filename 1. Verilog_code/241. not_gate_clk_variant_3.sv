//SystemVerilog
module not_gate_clk (
    input wire clk,
    input wire data_in,
    output reg data_out
);

    // Registers for pipelining
    reg data_inverted_reg1;
    reg data_inverted_reg2;

    // Combined always block for all pipeline stages
    always @ (posedge clk) begin
        // Pipeline stage 1: Perform inversion and register
        data_inverted_reg1 <= ~data_in;

        // Pipeline stage 2: Register the inverted data
        data_inverted_reg2 <= data_inverted_reg1;

        // Pipeline stage 3: Register the final output
        data_out <= data_inverted_reg2;
    end

endmodule