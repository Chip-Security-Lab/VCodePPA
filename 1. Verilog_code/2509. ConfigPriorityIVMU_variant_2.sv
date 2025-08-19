//SystemVerilog
module ConfigPriorityIVMU (
    input clk,
    input reset,
    input [7:0] irq_in,
    input [2:0] priority_cfg [0:7],
    input update_pri,
    input ready, // Added ready input for handshake
    output [31:0] isr_addr, // Changed to wire, driven by internal register
    output irq_out, // Changed to wire, driven by internal register
    output valid // Added valid output for handshake
);

    // Internal state storage
    reg [31:0] vector_table [0:7];
    reg [2:0] priorities [0:7];
    integer i; // Loop variable, not a physical signal to buffer

    // Buffered control and input signals for fanout reduction
    wire reset_buf;
    wire update_pri_buf;
    wire [7:0] irq_in_buf;
    wire [2:0] priorities_buf [0:7]; // Buffer for priorities array outputs

    assign reset_buf = reset;
    assign update_pri_buf = update_pri;
    assign irq_in_buf = irq_in;
    // Assign buffering for priorities array outputs
    generate
        for (genvar k = 0; k < 8; k++) begin : priorities_buf_gen
            assign priorities_buf[k] = priorities[k];
        end
    endgenerate


    // Pipeline Stage 1 Registers (Priority Encoding Output)
    reg pipe1_found_interrupt;
    reg [2:0] pipe1_highest_idx;
    reg [2:0] pipe1_highest_pri; // For visibility, lowest value is highest priority

    // Pipeline Stage 2 Registers (Vector Fetch Output)
    reg [31:0] pipe2_isr_addr;
    reg pipe2_irq_out; // Indicates if an interrupt was found in Stage 1
    reg pipe2_valid;   // Indicates if data in Stage 2 is valid

    // Output Registers (Pipeline Stage 3)
    reg [31:0] isr_addr_reg;
    reg irq_out_reg;
    reg valid_reg;

    // Assign outputs from output registers
    assign isr_addr = isr_addr_reg;
    assign irq_out = irq_out_reg;
    assign valid = valid_reg;

    //----------------------------------------------------------------------
    // Configuration Storage and Update
    // Stores the priority configuration for each IRQ.
    //----------------------------------------------------------------------
    always @(posedge clk or posedge reset_buf) begin // Use buffered reset
        if (reset_buf) begin
            // Reset priorities to default values (index-based)
            for (i = 0; i < 8; i = i + 1) priorities[i] <= i;
        end else if (update_pri_buf) begin // Use buffered update_pri
            // Update priorities from configuration input
            for (i = 0; i < 8; i = i + 1) priorities[i] <= priority_cfg[i];
        end
    end

    //----------------------------------------------------------------------
    // Vector Table Storage
    // Stores the ISR address for each IRQ index.
    // For synthesis, this is typically a ROM or constants.
    //----------------------------------------------------------------------
    initial begin // For simulation initialization
        for (i = 0; i < 8; i = i + 1) begin
            vector_table[i] = 32'h7000_0000 + (i * 64);
        end
    end

    //----------------------------------------------------------------------
    // Pipeline Stage 1: Combinatorial Priority Encoding
    // Finds the highest priority (lowest priority value) active IRQ.
    //----------------------------------------------------------------------
    // Outputs of the combinatorial block
    reg [2:0] comb_highest_pri;
    reg [2:0] comb_highest_idx;
    reg comb_found_interrupt;
    integer j;

    always @* begin
        // Initialize search with lowest possible priority value (highest number)
        comb_highest_pri = 3'h7;
        comb_highest_idx = 3'h0; // Default index if no interrupt found
        comb_found_interrupt = 0;

        // Iterate through IRQ inputs to find the highest priority pending interrupt
        // This loop synthesizes into combinatorial priority encoder logic
        for (j = 0; j < 8; j = j + 1) begin
            // Use buffered inputs
            if (irq_in_buf[j] && priorities_buf[j] < comb_highest_pri) begin
                comb_highest_pri = priorities_buf[j];
                comb_highest_idx = j[2:0]; // Capture the index
                comb_found_interrupt = 1;
            end
        end
        // Note: If multiple IRQs have the same highest priority,
        // the one with the highest index among them is selected.
    end

    // Intermediate buffered outputs of the combinatorial block
    wire [2:0] comb_highest_pri_buf;
    wire [2:0] comb_highest_idx_buf;
    wire comb_found_interrupt_buf;

    assign comb_highest_pri_buf = comb_highest_pri;
    assign comb_highest_idx_buf = comb_highest_idx;
    assign comb_found_interrupt_buf = comb_found_interrupt;


    //----------------------------------------------------------------------
    // Pipeline Stage 1: Sequential Registration
    // Registers the output of the combinatorial priority encoder.
    // Flushes on reset or configuration update.
    //----------------------------------------------------------------------
    always @(posedge clk or posedge reset_buf) begin // Use buffered reset
        if (reset_buf || update_pri_buf) begin // Use buffered update_pri
            pipe1_found_interrupt <= 0;
            pipe1_highest_idx <= 3'h0;
            pipe1_highest_pri <= 3'h7;
        end else begin
            // Register buffered combinatorial outputs
            pipe1_found_interrupt <= comb_found_interrupt_buf;
            pipe1_highest_idx <= comb_highest_idx_buf;
            pipe1_highest_pri <= comb_highest_pri_buf;
        end
    end

    //----------------------------------------------------------------------
    // Pipeline Stage 2: Combinatorial Vector Fetch
    // Looks up the ISR address based on the registered index from Stage 1.
    // Determines validity and irq_out signal for Stage 2.
    //----------------------------------------------------------------------
    wire [31:0] comb2_isr_addr;
    wire comb2_irq_out;
    wire comb2_valid;

    // Fetch vector table entry using the index from Stage 1
    assign comb2_isr_addr = vector_table[pipe1_highest_idx]; // pipe1_highest_idx is already registered
    // The IRQ_out signal for this stage is simply whether an interrupt was found in Stage 1
    assign comb2_irq_out = pipe1_found_interrupt; // pipe1_found_interrupt is already registered
    // Data in this stage is valid if an interrupt was found in Stage 1
    assign comb2_valid = pipe1_found_interrupt; // pipe1_found_interrupt is already registered

    // Intermediate buffered outputs of Stage 2 combinatorial logic
    wire [31:0] comb2_isr_addr_buf;
    wire comb2_irq_out_buf;
    wire comb2_valid_buf;

    assign comb2_isr_addr_buf = comb2_isr_addr;
    assign comb2_irq_out_buf = comb2_irq_out;
    assign comb2_valid_buf = comb2_valid;

    //----------------------------------------------------------------------
    // Pipeline Stage 2: Sequential Registration
    // Registers the output of the combinatorial vector fetch.
    // Flushes on reset or configuration update.
    //----------------------------------------------------------------------
    always @(posedge clk or posedge reset_buf) begin // Use buffered reset
        if (reset_buf || update_pri_buf) begin // Use buffered update_pri
            pipe2_isr_addr <= 32'h0;
            pipe2_irq_out <= 0;
            pipe2_valid <= 0;
        end else begin
            // Register buffered Stage 2 combinatorial outputs
            pipe2_isr_addr <= comb2_isr_addr_buf;
            pipe2_irq_out <= comb2_irq_out_buf;
            pipe2_valid <= comb2_valid_buf;
        end
    end

    //----------------------------------------------------------------------
    // Pipeline Stage 3: Output Registration and Handshake Logic
    // Manages the Valid-Ready handshake and registers the final output.
    // Holds data if not ready, loads new data from Stage 2 when possible.
    // Clears output on reset or configuration update.
    //----------------------------------------------------------------------
    always @(posedge clk or posedge reset_buf) begin // Use buffered reset
        if (reset_buf || update_pri_buf) begin // Use buffered update_pri
            valid_reg <= 0;
            irq_out_reg <= 0;
            isr_addr_reg <= 32'h0;
        end else if (valid_reg && !ready) begin
            // Output is valid and not consumed by receiver.
            // Hold current state: valid_reg remains 1, data is held.
        end else begin // (!valid_reg) or ready - Output can change
            // Either output was not valid, or receiver is ready.
            // Check if new valid data is available from the previous stage (Stage 2).
            if (pipe2_valid) begin // pipe2_valid is already registered
                // New valid data is available from Stage 2. Present it at the output.
                valid_reg <= 1;
                isr_addr_reg <= pipe2_isr_addr; // pipe2_isr_addr is already registered
                irq_out_reg <= pipe2_irq_out; // pipe2_irq_out is already registered
            end else begin
                // No new valid data from Stage 2. Deassert valid and clear output.
                valid_reg <= 0;
                isr_addr_reg <= 32'h0; // Clear data when valid is low
                irq_out_reg <= 0;      // Clear data when valid is low
            end
        end
    end

endmodule