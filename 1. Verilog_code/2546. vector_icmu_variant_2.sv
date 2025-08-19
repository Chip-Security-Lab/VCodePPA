//SystemVerilog
module vector_icmu (
    input clk,
    input rst_b,
    input [31:0] int_vector,
    input enable,
    input [63:0] current_context,
    output reg int_active,
    output reg [63:0] saved_context,
    output reg [4:0] vector_number
);

    // State registers
    reg [31:0] pending;
    reg [31:0] masked;
    reg [31:0] mask; // Mask register

    // Combinational signals
    wire [31:0] pending_or_int_vector; // Renamed for clarity
    wire [31:0] current_masked_interrupts;
    wire has_masked_interrupts;
    wire start_new_interrupt;
    wire [4:0] next_vector_number_candidate;

    // Calculate combinational intermediates
    assign pending_or_int_vector = pending | int_vector; // Accumulate new interrupts
    // Apply mask and enable gating using conditional operator
    assign current_masked_interrupts = enable ? (pending_or_int_vector & mask) : 32'b0;
    // Check if any masked interrupt is active
    assign has_masked_interrupts = |current_masked_interrupts;
    // Determine if a new interrupt sequence should start
    assign start_new_interrupt = !int_active && has_masked_interrupts;

    // Priority encoder function (finds the index of the MSB that is set)
    function [4:0] priority_encoder;
        input [31:0] vector;
        reg [4:0] result;
        integer i;
        begin
            result = 5'h0; // Default to 0
            // Iterate from MSB to LSB to find the highest priority set bit
            for (i = 31; i >= 0; i = i - 1) begin
                if (vector[i]) begin
                    result = i[4:0];
                    // Synthesis tools handle this loop efficiently for fixed size
                    // break; // SystemVerilog allows break
                end
            end
            priority_encoder = result;
        end
    endfunction

    // Calculate potential next vector number using the function
    assign next_vector_number_candidate = priority_encoder(current_masked_interrupts);

    // --- Synchronous Logic ---

    // Block 1: Mask Register (Reset Only)
    always @(posedge clk, negedge rst_b) begin
        if (!rst_b) begin
            mask <= 32'hFFFFFFFF; // Reset mask to enable all interrupts initially
        end
        // Mask is static after reset in this design
    end

    // Block 2: Pending Register (Accumulate and Clear)
    always @(posedge clk, negedge rst_b) begin
        if (!rst_b) begin
            pending <= 32'h0; // Reset pending interrupts
        end else begin
            // Accumulate new interrupts
            reg [31:0] pending_accumulated = pending | int_vector;
            // Conditionally clear the acknowledged bit if starting a new interrupt
            // Using conditional operator for clarity and potential PPA impact
            pending <= start_new_interrupt ?
                       (pending_accumulated & ~(32'h1 << next_vector_number_candidate)) : // Clear the bit corresponding to the vector number
                       pending_accumulated; // Keep accumulated value if not starting a new interrupt
        end
    end

    // Block 3: Masked Register (Delayed masked interrupts)
    always @(posedge clk, negedge rst_b) begin
        if (!rst_b) begin
            masked <= 32'h0; // Reset masked register
        end else begin
            // Update masked register based on current masked interrupts
            // This register reflects the masked state one cycle after pending updates
            masked <= current_masked_interrupts;
        end
    end

    // Block 4: Interrupt State Registers (int_active, saved_context, vector_number)
    // These registers update only when a new interrupt is being started
    always @(posedge clk, negedge rst_b) begin
        if (!rst_b) begin
            int_active <= 1'b0; // Reset interrupt active flag
            saved_context <= 64'h0; // Reset saved context
            vector_number <= 5'h0; // Reset vector number
        end else begin
            if (start_new_interrupt) begin
                // Latch the vector number of the highest priority interrupt
                vector_number <= next_vector_number_candidate;
                // Save the current context
                saved_context <= current_context;
                // Set the interrupt active flag
                int_active <= 1'b1;
            end
            // Note: int_active is NOT cleared here, matching original logic.
            // saved_context and vector_number hold their values if not updated.
            // This implicit latching/holding behavior is correctly described by
            // only assigning within the 'if' block.
        end
    end

endmodule