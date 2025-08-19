//SystemVerilog
// SystemVerilog
// Top module for the NOT gate system with pipelined data path
module not_gate_system (
    input wire sys_clk,     // System clock
    input wire sys_rst_n,   // System reset (active low)
    input wire i_A,         // Input signal A
    output wire o_Y          // Output signal Y
);

    // Internal signals for pipelined data path
    wire pipe_stage1_input;
    reg pipe_stage1_output_reg;
    wire pipe_stage2_input;
    wire pipe_stage2_output;

    // Stage 1: Input Latch
    assign pipe_stage1_input = i_A;

    // Register for Stage 1 output
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            pipe_stage1_output_reg <= 1'b0; // Reset to a known state
        end else begin
            pipe_stage1_output_reg <= pipe_stage1_input;
        end
    end

    // Stage 2: NOT gate core
    assign pipe_stage2_input = pipe_stage1_output_reg;

    not_gate_core u_not_gate_core (
        .i_data(pipe_stage2_input),
        .o_data(pipe_stage2_output)
    );

    // Assign final output
    assign o_Y = pipe_stage2_output;

endmodule

// Submodule implementing the core NOT gate functionality
module not_gate_core (
    input wire i_data,  // Input data
    output wire o_data  // Output data (inverted)
);

    // Implement the NOT logic
    assign o_data = ~i_data;

endmodule