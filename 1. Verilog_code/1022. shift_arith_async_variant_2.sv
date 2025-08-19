//SystemVerilog
// Top-level module: Hierarchical Arithmetic Right Shift with Asynchronous Operation
// Function: Delegates input/output to structured submodules for modularity and clarity

module shift_arith_async #(parameter W=8) (
    input  signed [W-1:0] din,
    input         [2:0]   shift,
    output signed [W-1:0] dout
);

    // Internal signals for submodule interconnection
    wire signed [W-1:0] pre_shift_data;
    wire signed [W-1:0] post_shift_data;

    // Input Latching Submodule: Latches the input data
    shift_input_latch #(.W(W)) u_input_latch (
        .in_data   (din),
        .latched_data (pre_shift_data)
    );

    // Arithmetic Right Shift Core Submodule
    shift_arith_core #(.W(W)) u_shift_core (
        .core_data_in   (pre_shift_data),
        .core_shift_amt (shift),
        .core_data_out  (post_shift_data)
    );

    // Output Register Submodule: Registers the shifted output
    shift_output_reg #(.W(W)) u_output_reg (
        .shifted_data (post_shift_data),
        .out_data     (dout)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: shift_input_latch
// Function: Latches input data to provide a clean interface to the shift core
// -----------------------------------------------------------------------------
module shift_input_latch #(parameter W=8) (
    input  signed [W-1:0] in_data,
    output signed [W-1:0] latched_data
);
    // Simple pass-through for asynchronous operation; can be replaced by a latch if needed
    assign latched_data = in_data;
endmodule

// -----------------------------------------------------------------------------
// Submodule: shift_arith_core
// Function: Performs signed arithmetic right shift operation
// -----------------------------------------------------------------------------
module shift_arith_core #(parameter W=8) (
    input  signed [W-1:0] core_data_in,
    input         [2:0]   core_shift_amt,
    output signed [W-1:0] core_data_out
);
    // Perform arithmetic right shift
    assign core_data_out = core_data_in >>> core_shift_amt;
endmodule

// -----------------------------------------------------------------------------
// Submodule: shift_output_reg
// Function: Registers the shifted output result for downstream modules
// -----------------------------------------------------------------------------
module shift_output_reg #(parameter W=8) (
    input  signed [W-1:0] shifted_data,
    output signed [W-1:0] out_data
);
    // Simple pass-through for asynchronous operation; can be replaced by a register if needed
    assign out_data = shifted_data;
endmodule