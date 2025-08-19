//SystemVerilog
//==============================================================================
// Module: irq_mask_unit
// Description: Masks the incoming interrupts based on the time slice.
// Inputs:
//   irq_in: 16-bit raw interrupt input
//   time_slice: 4-bit time slice index (0-15)
// Outputs:
//   masked_irq: 16-bit interrupts masked by the time slice
//==============================================================================
module irq_mask_unit (
    input  [15:0] irq_in,
    input  [3:0]  time_slice,
    output [15:0] masked_irq
);

    // Generate a mask based on the time slice
    wire [15:0] slice_mask;
    assign slice_mask = (16'h1 << time_slice);

    // Apply the mask to the incoming interrupts
    assign masked_irq = irq_in & slice_mask;

endmodule

//==============================================================================
// Module: priority_encoder_lookup
// Description: Detects the highest priority interrupt in the masked input
//              and looks up the corresponding vector address from a table.
// Inputs:
//   masked_irq: 16-bit masked interrupt input
// Outputs:
//   candidate_vector_addr: Candidate vector address for the highest priority IRQ
//   candidate_valid: Indicates if any interrupt is active in the masked input
//==============================================================================
module priority_encoder_lookup (
    input  [15:0] masked_irq,
    output [31:0] candidate_vector_addr,
    output        candidate_valid
);

    // Internal vector table
    reg [31:0] vector_table [0:15];
    integer i;

    // Initialize the vector table (can be parameterized or read from memory in real designs)
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            vector_table[i] = 32'hC000_0000 + (i << 6);
        end
    end

    // Determine if there is any valid interrupt in the masked slice
    assign candidate_valid = |masked_irq;

    // Determine the vector address for the highest priority interrupt in the masked slice
    reg [31:0] temp_vector_addr;
    always @(*) begin
        temp_vector_addr = 32'h0; // Default value if no interrupt is active
        // Iterate from highest priority (index 15) down to lowest (index 0)
        for (i = 15; i >= 0; i = i - 1) begin
            if (masked_irq[i]) begin
                // Assign the vector address for the highest priority active interrupt
                temp_vector_addr = vector_table[i];
                // No break needed, loop structure ensures highest index is kept
            end
        end
    end

    assign candidate_vector_addr = temp_vector_addr;

endmodule

//==============================================================================
// Module: output_register_handshake
// Description: Registers the candidate outputs and implements the Valid-Ready
//              handshake logic.
// Inputs:
//   clk: Clock signal
//   rst: Reset signal (active high)
//   ready: Ready signal from the receiver
//   candidate_vector_addr: Candidate vector address from previous stage
//   candidate_valid: Candidate valid signal from previous stage
// Outputs:
//   vector_addr: Registered output vector address
//   valid: Registered output valid signal
//==============================================================================
module output_register_handshake (
    input  clk,
    input  rst,
    input  ready,
    input  [31:0] candidate_vector_addr,
    input         candidate_valid,
    output reg [31:0] vector_addr,
    output reg valid
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            vector_addr <= 32'h0;
            valid <= 1'b0;
        end else begin
            // Update outputs only if the current output is not valid OR
            // the current output is valid AND the receiver is ready.
            // This implements the Valid-Ready handshake flow control.
            if (~valid || ready) begin
                vector_addr <= candidate_vector_addr;
                valid <= candidate_valid;
            end
            // Else: Hold current output (vector_addr and valid) if valid and not ready.
            // This is the default behavior of non-blocking assignments when the condition is false.
        end
    end

endmodule

//==============================================================================
// Module: TimeSlicedIVMU
// Description: Top-level module for the Time Sliced Interrupt Vector Memory Unit.
//              Coordinates interrupt masking, priority encoding, vector lookup,
//              and output registration with Valid-Ready handshake.
//              This module is a refactored version of the original flat design.
// Inputs:
//   clk: Clock signal
//   rst: Reset signal (active high)
//   irq_in: 16-bit raw interrupt input
//   time_slice: 4-bit time slice index (0-15)
//   ready: Ready signal from the receiver (for Valid-Ready handshake)
// Outputs:
//   vector_addr: Output vector address
//   valid: Output valid signal
//==============================================================================
module TimeSlicedIVMU (
    input clk,
    input rst,
    input [15:0] irq_in,
    input [3:0] time_slice,
    input ready,
    output [31:0] vector_addr,
    output valid
);

    // Intermediate signals connecting the submodules
    wire [15:0] masked_irq_w;
    wire [31:0] candidate_vector_addr_w;
    wire        candidate_valid_w;

    // Instantiate the interrupt masking unit
    irq_mask_unit u_irq_mask_unit (
        .irq_in     (irq_in),
        .time_slice (time_slice),
        .masked_irq (masked_irq_w)
    );

    // Instantiate the priority encoder and vector lookup unit
    priority_encoder_lookup u_priority_encoder_lookup (
        .masked_irq          (masked_irq_w),
        .candidate_vector_addr (candidate_vector_addr_w),
        .candidate_valid     (candidate_valid_w)
    );

    // Instantiate the output register and handshake unit
    output_register_handshake u_output_register_handshake (
        .clk                   (clk),
        .rst                   (rst),
        .ready                 (ready),
        .candidate_vector_addr (candidate_vector_addr_w),
        .candidate_valid       (candidate_valid_w),
        .vector_addr           (vector_addr),
        .valid                 (valid)
    );

endmodule