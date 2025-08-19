//SystemVerilog
// Submodule: Inverter (Functional Unit)
// Function: Performs a simple inversion operation
module inverter (
    input wire in_data,
    output wire out_data
);
    assign out_data = ~in_data;
endmodule

// Top module: not_gate_clk_hierarchical
// Function: Provides a clocked not gate functionality using a hierarchical structure
module not_gate_clk_hierarchical (
    input wire clk,
    input wire A,
    output wire Y
);

    // Register the input A on the positive edge of the clock
    reg A_reg;

    always @ (posedge clk) begin
        A_reg <= A;
    end

    // Internal wire to connect the inverter output to the output
    wire inverter_out;

    // Instantiate the inverter submodule
    inverter inv_inst (
        .in_data(A_reg), // Connect the registered input to the inverter
        .out_data(inverter_out)
    );

    // Assign the inverted output directly to the output Y
    // The register has been moved before the inverter
    assign Y = inverter_out;

endmodule