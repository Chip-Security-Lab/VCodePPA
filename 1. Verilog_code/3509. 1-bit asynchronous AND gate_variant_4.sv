//SystemVerilog
///////////////////////////////////////////////////////////
// File: top_and_gate.v
// Description: Parameterized hierarchical AND gate module
///////////////////////////////////////////////////////////

// Top-level AND gate module
module and_gate_1_async #(
    parameter INPUT_STAGES = 1,  // Input buffering stages
    parameter OUTPUT_STAGES = 1  // Output buffering stages
) (
    input wire a,  // Input A
    input wire b,  // Input B
    output wire y  // Output Y
);
    // Internal signals
    wire buffered_a;
    wire buffered_b;
    wire logic_out;
    
    // Input buffering submodule instance
    input_buffer #(
        .STAGES(INPUT_STAGES)
    ) input_buffer_inst (
        .a_in(a),
        .b_in(b),
        .a_out(buffered_a),
        .b_out(buffered_b)
    );
    
    // Logic operation submodule instance
    logic_operation logic_operation_inst (
        .a(buffered_a),
        .b(buffered_b),
        .y(logic_out)
    );
    
    // Output buffering submodule instance
    output_buffer #(
        .STAGES(OUTPUT_STAGES)
    ) output_buffer_inst (
        .in(logic_out),
        .out(y)
    );
    
endmodule

// Input buffer module with optional multi-stage buffering
module input_buffer #(
    parameter STAGES = 1  // Number of buffer stages
) (
    input wire a_in,
    input wire b_in,
    output wire a_out,
    output wire b_out
);
    // Generate buffer chain for input a
    genvar i;
    wire [STAGES:0] a_buff;
    wire [STAGES:0] b_buff;
    
    assign a_buff[0] = a_in;
    assign b_buff[0] = b_in;
    
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : buffer_stage
            assign a_buff[i+1] = a_buff[i];
            assign b_buff[i+1] = b_buff[i];
        end
    endgenerate
    
    assign a_out = a_buff[STAGES];
    assign b_out = b_buff[STAGES];
    
endmodule

// Core logic operation module
module logic_operation (
    input wire a,
    input wire b,
    output wire y
);
    // Perform the AND operation
    assign y = a & b;
    
endmodule

// Output buffer module with optional multi-stage buffering
module output_buffer #(
    parameter STAGES = 1  // Number of buffer stages
) (
    input wire in,
    output wire out
);
    // Generate buffer chain for output
    genvar i;
    wire [STAGES:0] buff;
    
    assign buff[0] = in;
    
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : buffer_stage
            assign buff[i+1] = buff[i];
        end
    endgenerate
    
    assign out = buff[STAGES];
    
endmodule