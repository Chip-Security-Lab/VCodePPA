//SystemVerilog
module TimeSlicedIVMU (
    input clk,
    input rst,
    input [15:0] irq_in,
    input [3:0] time_slice,
    input ready, // Input ready signal for Valid-Ready handshake (replaces ack)
    output logic valid, // Output valid signal (replaces req)
    output logic [31:0] vector_addr // Output vector address (data)
);
    // Memory for vector table
    logic [31:0] vector_table [0:15];

    // Combinatorial Signals
    logic [15:0] slice_masked;
    logic req_potential; // Potential request signal based on current inputs
    logic [31:0] vector_addr_potential; // Potential vector address based on current inputs

    // Intermediate combinatorial logic signal for priority encoder
    logic [31:0] vector_addr_potential_calc;

    // Next state signals (combinatorial calculation)
    logic next_valid;
    logic [31:0] next_vector_addr;

    integer i; // Loop variable (used in initial and combinatorial blocks)

    // --- Memory Initialization ---
    // Initialization of vector_table (Simulation/Synthesis)
    initial begin
        for (i = 0; i < 16; i = i + 1)
            vector_table[i] = 32'hC000_0000 + (i << 6);
    end

    // --- Combinatorial Logic ---

    // Calculate slice_masked based on irq_in and time_slice
    assign slice_masked = irq_in & (16'h1 << time_slice);

    // Determine if there is any pending interrupt in the current slice
    assign req_potential = |slice_masked;

    // Priority Encoder to determine vector_addr_potential from slice_masked
    always @(*) begin
        vector_addr_potential_calc = 32'h0; // Default value
        // Iterate from highest priority (15) down to lowest (0)
        for (i = 15; i >= 0; i = i - 1) begin
            if (slice_masked[i]) begin
                vector_addr_potential_calc = vector_table[i];
                // Priority is handled by the loop order
            end
        end
    end
    assign vector_addr_potential = vector_addr_potential_calc;

    // Combinatorial logic for next state calculation (next_valid)
    // Valid-Ready handshake logic
    always @(*) begin
        if (valid == 1'b0) begin // Current state: Idle (valid is low)
            next_valid = req_potential; // If new data is ready (req_potential=1), assert valid; otherwise stay low.
        end else begin // Current state: Sending (valid is high)
            if (ready == 1'b1) begin // Receiver ready
                next_valid = req_potential; // If new data is ready (req_potential=1), keep valid high for back-to-back; otherwise deassert valid.
            end else begin // Receiver not ready
                next_valid = 1'b1; // Keep valid asserted, waiting for ready.
            end
        end
    end

    // Combinatorial logic for next state calculation (next_vector_addr)
    // Update vector_addr based on Valid-Ready transfer completion and new data availability
    always @(*) begin
         // Update vector_addr only when starting a new transfer or continuing with new data
        if ((valid == 1'b0 && req_potential == 1'b1) || // Transition from Idle to Sending with new data
            (valid == 1'b1 && ready == 1'b1 && req_potential == 1'b1)) begin // Continuing Sending with new data (ready received and new data ready)
            next_vector_addr = vector_addr_potential; // Load the new potential address
        end else begin
            // In all other cases, the vector_addr should hold its current value.
            // This includes: Idle with no data, Sending waiting for ready, Sending ready received with no new data.
            next_vector_addr = vector_addr; // Hold current value
        end
    end

    // --- Sequential Logic ---

    // Register updates on positive clock edge or positive reset edge
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid <= 1'b0;
            vector_addr <= 32'h0; // Default reset value
        end else begin
            valid <= next_valid;
            vector_addr <= next_vector_addr;
        end
    end

endmodule