//SystemVerilog
// Top-level module
module priority_reset_dist #(
    parameter NUM_SOURCES = 4,
    parameter NUM_OUTPUTS = 8
)(
    input wire [NUM_SOURCES-1:0] reset_sources,
    input wire [NUM_SOURCES-1:0] priority_levels,
    output wire [NUM_OUTPUTS-1:0] reset_outputs
);
    // Internal signal for connecting submodules
    wire [3:0] highest_priority_source;
    
    // Instantiate priority encoder submodule
    priority_encoder #(
        .NUM_SOURCES(NUM_SOURCES)
    ) u_priority_encoder (
        .reset_sources(reset_sources),
        .highest_priority_source(highest_priority_source)
    );
    
    // Instantiate reset generator submodule
    reset_generator #(
        .NUM_SOURCES(NUM_SOURCES),
        .NUM_OUTPUTS(NUM_OUTPUTS)
    ) u_reset_generator (
        .highest_priority_source(highest_priority_source),
        .priority_levels(priority_levels),
        .reset_outputs(reset_outputs)
    );
    
endmodule

// Priority encoder module - determines the highest priority active reset source
module priority_encoder #(
    parameter NUM_SOURCES = 4
)(
    input wire [NUM_SOURCES-1:0] reset_sources,
    output reg [3:0] highest_priority_source
);
    // Default is no active source
    localparam NO_ACTIVE_SOURCE = 4'd15;
    
    always @(*) begin
        if (reset_sources[3])
            highest_priority_source = 4'd3;
        else if (reset_sources[2])
            highest_priority_source = 4'd2;
        else if (reset_sources[1])
            highest_priority_source = 4'd1;
        else if (reset_sources[0])
            highest_priority_source = 4'd0;
        else
            highest_priority_source = NO_ACTIVE_SOURCE;
    end
    
endmodule

// Reset generator module - generates reset outputs based on priority levels
module reset_generator #(
    parameter NUM_SOURCES = 4,
    parameter NUM_OUTPUTS = 8
)(
    input wire [3:0] highest_priority_source,
    input wire [NUM_SOURCES-1:0] priority_levels,
    output wire [NUM_OUTPUTS-1:0] reset_outputs
);
    // Default is no active source
    localparam NO_ACTIVE_SOURCE = 4'd15;
    
    // Internal signals for parallel prefix subtractor implementation
    wire [3:0] priority_value;
    wire [3:0] shift_amount;
    
    // Get the priority level for the active source
    assign priority_value = (highest_priority_source < NO_ACTIVE_SOURCE) ? 
                           {3'b000, priority_levels[highest_priority_source]} : 4'h0;
    
    // Parallel prefix subtractor to compute shift_amount = 0 - priority_value
    wire [3:0] b_complement;
    wire [4:0] carry;  // Extra bit for carry
    wire [3:0] propagate, generate_sig;
    wire [3:0] group_propagate, group_generate;
    
    // Step 1: Initial bit-level propagate and generate signals
    assign b_complement = priority_value ^ 4'b1111;  // One's complement of B
    assign propagate = 4'b0000;  // For subtraction, propagate is 0
    assign generate_sig = b_complement;  // Generate is one's complement of B
    assign carry[0] = 1'b1;  // Initial carry-in of 1 for subtraction
    
    // Step 2: Group propagate and generate for prefix computation
    // Level 1: Compute prefix for 2-bit groups
    assign group_propagate[0] = propagate[0];
    assign group_generate[0] = generate_sig[0];
    
    assign group_propagate[1] = propagate[1] & propagate[0];
    assign group_generate[1] = generate_sig[1] | (propagate[1] & generate_sig[0]);
    
    assign group_propagate[2] = propagate[2];
    assign group_generate[2] = generate_sig[2];
    
    assign group_propagate[3] = propagate[3] & propagate[2];
    assign group_generate[3] = generate_sig[3] | (propagate[3] & generate_sig[2]);
    
    // Step 3: Compute carries
    assign carry[1] = generate_sig[0] | (propagate[0] & carry[0]);
    assign carry[2] = group_generate[1] | (group_propagate[1] & carry[0]);
    assign carry[3] = generate_sig[2] | (propagate[2] & carry[2]);
    assign carry[4] = group_generate[3] | (group_propagate[3] & carry[2]);
    
    // Step 4: Compute sum bits
    assign shift_amount = b_complement ^ {carry[3:0]};
    
    // Generate reset outputs based on computed shift amount
    assign reset_outputs = (highest_priority_source < NO_ACTIVE_SOURCE) ? 
                          (8'hFF >> shift_amount) : 8'h0;
    
endmodule