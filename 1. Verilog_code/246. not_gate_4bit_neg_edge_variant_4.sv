//SystemVerilog
// SystemVerilog
// Module: not_gate_4bit_neg_edge_retimed_pipelined
// Description: 4-bit NOT gate with negative edge clock and 2-stage pipeline
// Data flow is structured into explicit pipeline stages for clarity and timing control.

module not_gate_4bit_neg_edge_retimed_pipelined (
    input wire clk,  // Negative edge clock
    input wire [3:0] A,  // 4-bit input data
    output reg [3:0] Y   // 4-bit output data
);

    // Internal signals representing pipeline stages
    reg [3:0] pipeline_stage1_input_reg;       // Register for input A
    wire [3:0] pipeline_stage1_inverted_data;  // Wire for inverted data after stage 1 logic
    reg [3:0] pipeline_stage2_output_reg;      // Register for final output Y

    // Stage 1: Input Register
    // Registers the input 'A' on the negative edge of the clock.
    always @ (negedge clk) begin
        pipeline_stage1_input_reg <= A;
    end

    // Stage 1 Logic: Inversion
    // Performs the NOT operation on the registered input.
    assign pipeline_stage1_inverted_data = ~pipeline_stage1_input_reg;

    // Stage 2: Output Register
    // Registers the inverted data on the negative edge of the clock.
    // This register holds the final output value.
    always @ (negedge clk) begin
        pipeline_stage2_output_reg <= pipeline_stage1_inverted_data;
    end

    // Output Assignment
    // Assigns the final registered value to the output port Y.
    assign Y = pipeline_stage2_output_reg;

endmodule