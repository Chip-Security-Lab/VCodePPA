//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Design Name: and_gate_reset_hierarchical
// Module: and_gate_reset
// Description: 2-input AND gate with synchronous reset functionality,
//              hierarchically restructured with pipelined data path
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module and_gate_reset (
    input  wire clk,    // Clock input
    input  wire a,      // Input A
    input  wire b,      // Input B
    input  wire rst,    // Reset signal
    output wire y       // Output Y
);

    // Internal signals for module connections
    wire a_registered, b_registered, rst_registered;
    wire and_result;

    // Input Registration Module
    input_register input_reg_inst (
        .clk        (clk),
        .a_in       (a),
        .b_in       (b),
        .rst_in     (rst),
        .a_out      (a_registered),
        .b_out      (b_registered),
        .rst_out    (rst_registered)
    );

    // Computation Module
    compute_unit compute_inst (
        .clk        (clk),
        .a          (a_registered),
        .b          (b_registered),
        .result     (and_result)
    );

    // Output Control Module
    output_control output_ctrl_inst (
        .clk        (clk),
        .data_in    (and_result),
        .rst        (rst_registered),
        .data_out   (y)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: input_register
// Description: Registers all input signals
///////////////////////////////////////////////////////////////////////////////
module input_register (
    input  wire clk,        // Clock input
    input  wire a_in,       // Input A
    input  wire b_in,       // Input B
    input  wire rst_in,     // Reset signal
    output reg  a_out,      // Registered A
    output reg  b_out,      // Registered B
    output reg  rst_out     // Registered Reset
);

    // Register all inputs
    always @(posedge clk) begin
        a_out   <= a_in;
        b_out   <= b_in;
        rst_out <= rst_in;
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: compute_unit
// Description: Performs the AND operation on registered inputs
///////////////////////////////////////////////////////////////////////////////
module compute_unit (
    input  wire clk,        // Clock input
    input  wire a,          // Registered input A
    input  wire b,          // Registered input B
    output reg  result      // AND result
);

    // Compute AND logic
    always @(posedge clk) begin
        result <= a & b;
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: output_control
// Description: Applies reset condition and outputs final result
///////////////////////////////////////////////////////////////////////////////
module output_control (
    input  wire clk,        // Clock input
    input  wire data_in,    // Computed data
    input  wire rst,        // Reset signal
    output reg  data_out    // Final output
);

    // Apply reset and output final result
    always @(posedge clk) begin
        data_out <= rst ? 1'b0 : data_in;
    end

endmodule