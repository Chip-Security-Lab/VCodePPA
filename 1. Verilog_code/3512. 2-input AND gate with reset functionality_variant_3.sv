//SystemVerilog
//IEEE 1364-2005 Verilog
// Top level module: and_gate_reset
// Description: 2-input AND gate with reset functionality, pipelined implementation
module and_gate_reset (
    input  wire clk,      // Clock signal (added for pipelining)
    input  wire a,        // Input A
    input  wire b,        // Input B
    input  wire rst,      // Reset signal
    output wire y         // Output Y
);
    // Pipeline stage signals
    reg  stage1_a, stage1_b;       // Stage 1 registered inputs
    wire stage1_and_result;        // Stage 1 AND result
    reg  stage2_and_result;        // Stage 2 registered AND result
    wire stage2_reset_out;         // Stage 2 reset control output

    // Stage 1: Input Registration and AND Operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
        end else begin
            stage1_a <= a;
            stage1_b <= b;
        end
    end

    // Instantiate logical operation submodule with registered inputs
    and_operation and_op_inst (
        .a(stage1_a),
        .b(stage1_b),
        .result(stage1_and_result)
    );
    
    // Stage 2: Register the AND result
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage2_and_result <= 1'b0;
        end else begin
            stage2_and_result <= stage1_and_result;
        end
    end
    
    // Instantiate reset control submodule with registered AND result
    reset_control rst_ctrl_inst (
        .data_in(stage2_and_result),
        .rst(rst),
        .data_out(stage2_reset_out)
    );
    
    // Output assignment (could be registered for an additional pipeline stage if needed)
    assign y = stage2_reset_out;
    
endmodule

// Submodule: AND logical operation - optimized for timing
module and_operation (
    input  wire a,          // Input A
    input  wire b,          // Input B
    output wire result      // AND result
);
    // Parameter for potential customization
    parameter ENABLE = 1'b1;
    
    // Efficient implementation with enable control
    assign result = ENABLE ? (a & b) : 1'b0;
endmodule

// Submodule: Reset control logic - enhanced for better timing closure
module reset_control (
    input  wire data_in,    // Input data
    input  wire rst,        // Reset signal
    output wire data_out    // Output data with reset control applied
);
    // Parameter for reset polarity
    parameter RESET_ACTIVE_HIGH = 1'b1;
    
    // Optimized reset implementation for better timing
    wire reset_active;
    
    // Determine if reset is active based on polarity parameter
    assign reset_active = (rst == RESET_ACTIVE_HIGH);
    
    // Apply reset control to data path
    assign data_out = reset_active ? 1'b0 : data_in;
endmodule