//SystemVerilog
module not_gate_top (
    input wire clk,
    input wire reset,
    input wire in_A,
    output wire out_Y
);

    // Internal signal for registered input
    logic reg_in_A;

    // Register the input signal
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_in_A <= 1'b0;
        end else begin
            reg_in_A <= in_A;
        end
    end

    // Instantiate the Not gate functional module with registered input
    not_gate_func u_not_gate_func (
        .in(reg_in_A),
        .out(out_Y)
    );

endmodule

// Functional module for the NOT gate logic
module not_gate_func (
    input wire in,
    output wire out
);

    // Assign the inverted input to the output
    assign out = ~in;

endmodule