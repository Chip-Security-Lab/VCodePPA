//SystemVerilog
//------------------------------------------------------------------------------
// Top-level module for Vector Interrupt Controller Unit (ICMU)
// Refactored: Pipelined data path and control logic for improved timing
// and structure.
// Stages:
// Stage 0: Pending interrupt management (registered)
// Stage 1: Masking and Priority Encoding (combinatorial)
// Stage 1 Reg: Register outputs of Stage 1
// Stage 2: Trigger Logic, Control Signal Generation (registered), State Update (registered)
//------------------------------------------------------------------------------
module vector_icmu (
    input clk,
    input rst_b,
    input [31:0] int_vector,        // Incoming interrupt vector
    input enable,                   // Global enable for interrupt handling
    input [63:0] current_context,   // Context to save upon interrupt
    output reg int_active,          // Indicates an interrupt is being serviced
    output reg [63:0] saved_context,// Saved context upon interrupt
    output reg [4:0] vector_number  // Vector number of the active interrupt
);

    //--------------------------------------------------------------------------
    // Internal Signals and Registers
    //--------------------------------------------------------------------------

    // Mask register (static after reset)
    reg [31:0] mask_reg;

    // Stage 0 Output (Pending Manager Output)
    wire [31:0] pending_stage0_out;

    // Stage 1 Combinatorial Outputs (Masking and Encoding)
    wire [31:0] stage1_masked_comb;
    wire [4:0] stage1_vector_number_comb;
    wire stage1_interrupt_pending_flag_comb;

    // Stage 1 Pipeline Registers
    reg [31:0] pipe1_masked_reg;
    reg [4:0] pipe1_vector_number_reg;
    reg pipe1_interrupt_pending_flag_reg;

    // Stage 2 Combinatorial Trigger Condition (based on Stage 1 Reg outputs and Stage 2 Reg output)
    wire pipe1_trigger_condition_comb;

    // Stage 2 Pipeline Registers (Control Signals for Stage 0 and Stage 2)
    reg pipe2_load_state_en_reg;
    reg pipe2_clear_pending_en_reg;
    reg [4:0] pipe2_clear_vector_reg;

    //--------------------------------------------------------------------------
    // Mask Register Logic (Stage 0/Global)
    //--------------------------------------------------------------------------
    always @(posedge clk, negedge rst_b) begin
        if (!rst_b) begin
            mask_reg <= 32'hFFFFFFFF; // Reset mask to all ones
        end else begin
            // Mask is static after reset in this implementation
            // Add logic here if mask needs to be configurable/writable
        end
    end

    //--------------------------------------------------------------------------
    // Stage 0: Pending Interrupt Manager
    // Manages the pending interrupt register.
    // Inputs: int_vector, pipe2_clear_pending_en_reg, pipe2_clear_vector_reg
    // Output: pending_stage0_out (registered output from the module)
    //--------------------------------------------------------------------------
    interrupt_pending_manager i_pending_manager (
        .clk(clk),
        .rst_b(rst_b),
        .int_vector(int_vector),
        .clear_en(pipe2_clear_pending_en_reg), // Use registered enable from Stage 2
        .clear_vector(pipe2_clear_vector_reg), // Use registered vector from Stage 2
        .pending_out(pending_stage0_out)
    );

    //--------------------------------------------------------------------------
    // Stage 1: Masking and Priority Encoding (Combinatorial Logic)
    // Applies mask/enable and finds highest priority vector.
    // Inputs: pending_stage0_out, enable, mask_reg
    // Outputs: stage1_masked_comb, stage1_vector_number_comb, stage1_interrupt_pending_flag_comb
    //--------------------------------------------------------------------------

    // Stage 1 Sub-module: Masker
    interrupt_masker i_masker (
        .pending_in(pending_stage0_out),
        .enable(enable),
        .mask(mask_reg),
        .masked_out(stage1_masked_comb)
    );

    // Stage 1 Sub-module: Priority Encoder
    priority_encoder_32_to_5 i_priority_encoder (
        .vector_in(stage1_masked_comb),
        .vector_number(stage1_vector_number_comb),
        .interrupt_pending(stage1_interrupt_pending_flag_comb)
    );

    //--------------------------------------------------------------------------
    // Stage 1 Reg: Pipeline Registers
    // Register the combinatorial outputs of Stage 1.
    //--------------------------------------------------------------------------
    always @(posedge clk, negedge rst_b) begin
        if (!rst_b) begin
            pipe1_masked_reg <= 32'h0;
            pipe1_vector_number_reg <= 5'h0;
            pipe1_interrupt_pending_flag_reg <= 1'b0;
        end else begin
            pipe1_masked_reg <= stage1_masked_comb;
            pipe1_vector_number_reg <= stage1_vector_number_comb;
            pipe1_interrupt_pending_flag_reg <= stage1_interrupt_pending_flag_comb;
        end
    end

    //--------------------------------------------------------------------------
    // Stage 2: Trigger Logic and Control Signal Generation
    // Determines if an interrupt service should be triggered based on
    // Stage 1 registered outputs and current state. Generates registered
    // control signals for Stage 0 and Stage 2.
    //--------------------------------------------------------------------------

    // Combinatorial trigger condition based on registered signals
    // Trigger if not currently active AND there is a pending masked interrupt
    assign pipe1_trigger_condition_comb = (!int_active && pipe1_interrupt_pending_flag_reg);

    // Register control signals for Stage 2 (State Registers) and Stage 0 (Pending Manager)
    always @(posedge clk, negedge rst_b) begin
        if (!rst_b) begin
            pipe2_load_state_en_reg <= 1'b0;
            pipe2_clear_pending_en_reg <= 1'b0;
            pipe2_clear_vector_reg <= 5'h0;
        end else begin
            // Load enable and clear pending enable pulse high for one cycle
            // when the Stage 1 trigger condition was met
            pipe2_load_state_en_reg <= pipe1_trigger_condition_comb;
            pipe2_clear_pending_en_reg <= pipe1_trigger_condition_comb;

            // Latch the vector number when the Stage 1 trigger condition was met
            if (pipe1_trigger_condition_comb) begin
                pipe2_clear_vector_reg <= pipe1_vector_number_reg;
            end
            // else keep current value (implicit latch)
        end
    end

    //--------------------------------------------------------------------------
    // Stage 2: State Registers
    // Registers the final output state (active flag, saved context, vector number).
    // Loaded when signaled by the Stage 2 load enable.
    // Inputs: pipe2_load_state_en_reg, pipe1_vector_number_reg, current_context
    // Outputs: int_active, saved_context, vector_number (registered outputs)
    //--------------------------------------------------------------------------
    interrupt_state_registers i_state_registers (
        .clk(clk),
        .rst_b(rst_b),
        .load_en(pipe2_load_state_en_reg),    // Use registered enable from Stage 2
        .vector_number_in(pipe1_vector_number_reg), // Use registered vector from Stage 1 Reg
        .current_context_in(current_context), // current_context is captured when pipe2_load_state_en_reg is high
        .int_active_out(int_active),
        .saved_context_out(saved_context),
        .vector_number_out(vector_number)
    );

endmodule

//------------------------------------------------------------------------------
// Module: interrupt_pending_manager
// Manages the pending interrupt register. It accumulates new interrupts
// and clears a specific bit when signaled by the control logic.
// This module is Stage 0 in the pipeline.
//------------------------------------------------------------------------------
module interrupt_pending_manager (
    input clk,
    input rst_b,
    input [31:0] int_vector,        // New incoming interrupts
    input clear_en,                 // Enable to clear a pending bit (registered input from Stage 2)
    input [4:0] clear_vector,       // Vector number to clear (registered input from Stage 2)
    output [31:0] pending_out       // Current pending interrupts (registered output)
);

    reg [31:0] pending_reg;

    always @(posedge clk, negedge rst_b) begin
        if (!rst_b) begin
            pending_reg <= 32'h0; // Reset pending register
        end else begin
            reg [31:0] next_pending = pending_reg | int_vector; // Accumulate new interrupts
            if (clear_en) begin // clear_en is a registered signal from Stage 2
                next_pending = next_pending & ~(32'h1 << clear_vector); // Clear specified bit if enabled
            end
            pending_reg <= next_pending;
        end
    end

    assign pending_out = pending_reg; // Output the current pending state (registered)

endmodule

//------------------------------------------------------------------------------
// Module: interrupt_masker
// Applies the mask and global enable to the pending interrupts.
// This module is part of Stage 1 (combinatorial).
//------------------------------------------------------------------------------
module interrupt_masker (
    input [31:0] pending_in,    // Pending interrupts (from Stage 0)
    input enable,               // Global enable signal
    input [31:0] mask,          // Mask value (from top module)
    output [31:0] masked_out    // Masked and enabled interrupts (combinatorial output)
);

    // Apply mask and enable (combinational)
    assign masked_out = pending_in & mask & {32{enable}};

endmodule

//------------------------------------------------------------------------------
// Module: priority_encoder_32_to_5
// Finds the highest priority bit set in a 32-bit vector and outputs
// its index (vector number) and a flag indicating if any bit is set.
// This is a combinational module, part of Stage 1.
//------------------------------------------------------------------------------
module priority_encoder_32_to_5 (
    input [31:0] vector_in,         // Input vector (from masker)
    output [4:0] vector_number,     // Index of the highest set bit (combinatorial output)
    output interrupt_pending        // Flag: 1 if any bit in vector_in is set (combinatorial output)
);

    reg [4:0] result;
    integer i;

    // Combinational priority encoding logic
    always @(*) begin
        result = 5'h0; // Default to 0
        // Iterate from highest priority (31) down to lowest (0)
        for (i = 31; i >= 0; i = i - 1) begin
            if (vector_in[i]) begin
                result = i[4:0]; // Found highest priority bit
                // The loop structure naturally implements priority:
                // the assignment for the highest 'i' that is true overwrites
                // any previous assignments for lower 'i'.
            end
        end
    end

    assign vector_number = result;
    assign interrupt_pending = |vector_in; // Check if any bit is set

endmodule


//------------------------------------------------------------------------------
// Module: interrupt_state_registers
// Registers the output state signals (int_active, saved_context, vector_number).
// These registers are loaded when signaled by the control logic.
// This module is part of Stage 2.
//------------------------------------------------------------------------------
module interrupt_state_registers (
    input clk,
    input rst_b,
    input load_en,                  // Enable signal to load registers (registered input from Stage 2)
    input [4:0] vector_number_in,   // Vector number to register (registered input from Stage 1 Reg)
    input [63:0] current_context_in,// Context to register (combinatorial input)
    output reg int_active_out,      // Registered int_active state
    output reg [63:0] saved_context_out,// Registered saved_context
    output reg [4:0] vector_number_out // Registered vector_number
);

    always @(posedge clk, negedge rst_b) begin
        if (!rst_b) begin
            int_active_out <= 1'b0;         // Reset int_active
            saved_context_out <= 64'h0;     // Reset saved_context
            vector_number_out <= 5'h0;      // Reset vector_number
        end else begin
            if (load_en) begin // Load registers on enable (load_en is a registered signal from Stage 2)
                int_active_out <= 1'b1;     // Set int_active high (stays high until externally cleared - not shown here)
                saved_context_out <= current_context_in; // Save context
                vector_number_out <= vector_number_in;   // Register vector number
            end
        end
    end

endmodule