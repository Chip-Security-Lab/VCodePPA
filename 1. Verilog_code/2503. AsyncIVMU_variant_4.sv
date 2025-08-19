//SystemVerilog
// Vector Lookup Submodule
// Stores a mapping of index to vector and provides combinational lookup
module VectorLookup_8x32 (
    input [2:0] lookup_index,
    output [31:0] lookup_vector
);

    // Vector map storage - Use reg array as in original
    reg [31:0] vector_map [0:7];
    integer i; // Use integer for loop variable

    // Initialization of the vector map
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            vector_map[i] = 32'h2000_0000 + (i * 4);
        end
    end

    // Combinational lookup
    assign lookup_vector = vector_map[lookup_index];

endmodule


// Priority Encoder Submodule
// Finds the highest index of a set bit and indicates if any bit is set
module PriorityEncoder_8to3 (
    input [7:0] masked_inputs,
    output [2:0] priority_index,
    output active_flag
);

    // active_flag is true if any bit in masked_inputs is set
    assign active_flag = |masked_inputs;

    reg [2:0] p_index;
    integer i; // Use integer for loop variable

    // Combinational logic to find the highest priority index
    always @(*) begin
        p_index = 0; // Default value if no input is active (can be any value, 0 is safe)
        // Iterate from highest priority (index 7) down to lowest (index 0)
        for (i = 7; i >= 0; i = i - 1) begin
            if (masked_inputs[i]) begin
                p_index = i[2:0]; // Assign the index of the highest set bit
                // The loop structure ensures that the highest index is assigned last
            end
        end
    end

    assign priority_index = p_index;

endmodule


// Top Module for Asynchronous Interrupt Vector Mapping Unit
// Refactored into submodules for priority encoding and vector lookup
module AsyncIVMU (
    input [7:0] int_lines,
    input [7:0] int_mask,
    output [31:0] vector_out,
    output int_active
);

    // Internal signals for communication between submodules
    wire [7:0] masked_interrupts;
    wire [2:0] active_interrupt_index;
    wire any_interrupt_active;

    // 1. Masking Logic: Apply mask to interrupt lines
    // This logic remains in the top module as it's a simple input processing step
    assign masked_interrupts = int_lines & ~int_mask;

    // 2. Instantiate Priority Encoder submodule
    // This module identifies the highest priority active interrupt index
    PriorityEncoder_8to3 priority_encoder_inst (
        .masked_inputs (masked_interrupts),
        .priority_index (active_interrupt_index),
        .active_flag    (any_interrupt_active)
    );

    // 3. Instantiate Vector Lookup submodule
    // This module looks up the corresponding vector based on the active index
    VectorLookup_8x32 vector_lookup_inst (
        .lookup_index (active_interrupt_index),
        .lookup_vector (vector_out)
    );

    // Connect the active flag from the priority encoder to the top output
    assign int_active = any_interrupt_active;

endmodule