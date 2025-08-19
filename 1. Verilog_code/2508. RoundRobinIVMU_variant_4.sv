//SystemVerilog
module RoundRobinIVMU (
    input clk,
    input rst,
    input [7:0] irq,
    input ack,
    output reg [31:0] vector,
    output reg valid
);

    // Internal state registers
    reg [2:0] last_served;
    reg [7:0] pending;

    // Vector table (constant)
    reg [31:0] vector_table [0:7];

    // Initialization of vector table
    initial begin
        vector_table[0] = 32'h6000_0000;
        vector_table[1] = 32'h6000_0020;
        vector_table[2] = 32'h6000_0040;
        vector_table[3] = 32'h6000_0060;
        vector_table[4] = 32'h6000_0080;
        vector_table[5] = 32'h6000_00A0;
        vector_table[6] = 32'h6000_00C0;
        vector_table[7] = 32'h6000_00E0;
    end

    // --- Combinatorial Logic for Next State Calculation ---

    // Combine current pending interrupts with new requests
    wire [7:0] current_pending = pending | irq;

    // Determine if a search for a new interrupt is needed
    // Search is needed if not currently valid and there are any pending interrupts after considering new requests
    wire search_needed = !valid && (|current_pending);

    // Calculate the index to start searching from (next after last_served, wrapping around)
    wire [2:0] search_start_idx = (last_served + 1) % 8;

    // Wires to represent the indices and their pending status in priority order
    // potential_idx[0] corresponds to (last_served + 1) % 8 (highest priority)
    // potential_idx[7] corresponds to last_served (lowest priority in search)
    wire [2:0] potential_idx [0:7];
    wire potential_pending [0:7];

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : check_indices
            // Calculate the actual index being checked in this priority slot
            assign potential_idx[i] = (search_start_idx + i) % 8;
            // Check if the interrupt at this index is pending in the combined pending state
            assign potential_pending[i] = current_pending[potential_idx[i]];
        end
    endgenerate

    // Find the first pending interrupt according to the defined priority
    wire [2:0] found_idx;
    wire found_interrupt;

    // found_interrupt is true if any of the potential indices is pending
    assign found_interrupt = potential_pending[0] | potential_pending[1] | potential_pending[2] | potential_pending[3] |
                             potential_pending[4] | potential_pending[5] | potential_pending[6] | potential_pending[7];

    // found_idx is the index of the first pending interrupt in priority order
    // This implements the priority encoder logic
    assign found_idx = potential_pending[0] ? potential_idx[0] :
                       potential_pending[1] ? potential_idx[1] :
                       potential_pending[2] ? potential_idx[2] :
                       potential_pending[3] ? potential_idx[3] :
                       potential_pending[4] ? potential_idx[4] :
                       potential_pending[5] ? potential_idx[5] :
                       potential_pending[6] ? potential_idx[6] :
                       potential_idx[7]; // If none of the first 7 are pending, it must be the 8th (last_served) if found_interrupt is true

    // Calculate the next state values for registers based on current state and combinatorial results
    reg [2:0] next_last_served;
    reg [31:0] next_vector;
    reg [7:0] next_pending;
    reg next_valid;

    always @* begin
        // Default next state is current state or derived values
        next_last_served = last_served;
        next_vector = vector;
        next_pending = current_pending; // Start with combined pending interrupts
        next_valid = valid;

        // If acknowledged, clear valid flag in the next cycle
        if (ack) begin
            next_valid = 1'b0;
        end

        // If a search is needed and an interrupt was found
        // This block determines the state transitions when a new interrupt is served
        if (search_needed && found_interrupt) begin
            next_valid = 1'b1; // Assert valid in the next cycle to indicate vector is ready
            next_vector = vector_table[found_idx]; // Provide the vector for the found interrupt
            // Clear the pending bit for the served interrupt in the next cycle
            next_pending = current_pending & ~(1 << found_idx);
            next_last_served = found_idx; // Update last_served to the index of the served interrupt
        end
        // If search_needed is true but found_interrupt is false, it implies a logic issue
        // where |current_pending is true but no single bit was detected as set.
        // In a correct scenario, found_interrupt should be true if search_needed is true.
        // The default assignment 'next_valid = valid' (which is 0 when search_needed is true)
        // handles this case gracefully by keeping valid low.
    end

    // --- Registered Logic ---

    // Update state registers on positive clock edge or positive reset edge
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset state
            last_served <= 3'b0;
            pending <= 8'b0;
            valid <= 1'b0;
            vector <= 32'h0;
        end else begin
            // Update state from combinatorial next-state calculations
            last_served <= next_last_served;
            pending <= next_pending;
            valid <= next_valid;
            vector <= next_vector;
        end
    end

endmodule