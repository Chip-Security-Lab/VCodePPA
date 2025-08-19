//SystemVerilog
// Top module: DynamicMapIVMU
// Manages IRQ mapping and generates corresponding vector addresses.
// Pipelined version for improved throughput.
module DynamicMapIVMU (
    input clk,
    input reset,
    input [7:0] irq,           // Incoming IRQ signals (priority 7 is highest)
    input [2:0] map_idx,       // Index into the IRQ map to update [0-7]
    input [2:0] map_irq_num,   // IRQ number to map to map_idx's vector index [0-7]
    input map_update,          // Pulse to update the IRQ map
    output reg [31:0] irq_vector, // Output vector address for the highest pending IRQ
    output reg irq_valid         // Indicates if any IRQ is pending
);

    logic [7:0][2:0] current_irq_map;

    parameter [31:0] VECTOR_BASE = 32'hA000_0000;

    logic [31:0] calculated_irq_vector_pipe;
    logic calculated_irq_valid_pipe;

    irq_map_reg map_reg_inst (
        .clk(clk),
        .reset(reset),
        .map_update(map_update),
        .map_idx(map_idx),
        .map_irq_num(map_irq_num),
        .irq_map_o(current_irq_map)
    );

    irq_vector_pipeline vector_pipe_inst (
        .clk(clk),
        .reset(reset),
        .irq_i(irq),
        .irq_map_i(current_irq_map),
        .vector_base_i(VECTOR_BASE),
        .irq_vector_pipe_o(calculated_irq_vector_pipe),
        .irq_valid_pipe_o(calculated_irq_valid_pipe)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            irq_valid <= 1'b0;
            irq_vector <= 32'h0000_0000;
        end else if (map_update) begin
            // Hold outputs when map_update is active
        end else begin
            irq_valid <= calculated_irq_valid_pipe;
            irq_vector <= calculated_irq_vector_pipe;
        end
    end

endmodule

// irq_map_reg module
// Handles the storage and synchronous update of the IRQ mapping array.
module irq_map_reg (
    input clk,           // Clock signal
    input reset,         // Asynchronous reset signal
    input map_update,    // Pulse to trigger a map update
    input [2:0] map_idx, // Index of the map entry to update [0-7]
    input [2:0] map_irq_num, // The IRQ number to map to map_idx's vector index [0-7]
    output reg [7:0][2:0] irq_map_o // The current state of the IRQ map array
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 8; i++) begin
                irq_map_o[i] <= i[2:0];
            end
        end else if (map_update) begin
            irq_map_o[map_idx] <= map_irq_num;
        end
    end

endmodule

// irq_vector_pipeline module
// Performs the pipelined logic to calculate the IRQ vector and valid signal.
module irq_vector_pipeline (
    input clk,           // Clock signal
    input reset,         // Asynchronous reset signal
    input [7:0] irq_i,           // Current IRQ signals
    input [7:0][2:0] irq_map_i, // Current state of the IRQ map
    input [31:0] vector_base_i,  // Base address for vector calculation
    output [31:0] irq_vector_pipe_o, // Calculated vector address (pipelined)
    output irq_valid_pipe_o         // Calculated valid signal (pipelined)
);

    // --- Stage 0: Priority Encoding, Map Lookup, Any Active Check ---
    logic [2:0] highest_irq_idx_st0_comb;
    logic [2:0] mapped_idx_st0_comb;
    logic is_any_irq_active_st0_comb;

    always_comb begin
        highest_irq_idx_st0_comb = 3'b000; // Default if no IRQ is active
        is_any_irq_active_st0_comb = 1'b0;
        // Iterate from highest priority (7) down to lowest (0)
        for (int i = 7; i >= 0; i--) begin
            if (irq_i[i]) begin
                highest_irq_idx_st0_comb = i[2:0];
                is_any_irq_active_st0_comb = 1'b1;
                // Priority is handled by the loop order
            end
        end
        // Lookup mapped index based on highest priority IRQ index
        mapped_idx_st0_comb = irq_map_i[highest_irq_idx_st0_comb];
    end

    // --- Stage 1: Register Stage 0 Outputs ---
    logic [2:0] highest_irq_idx_st1;
    logic [2:0] mapped_idx_st1;
    logic is_any_irq_active_st1;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            highest_irq_idx_st1 <= 3'b000;
            mapped_idx_st1 <= 3'b000;
            is_any_irq_active_st1 <= 1'b0;
        end else begin
            highest_irq_idx_st1 <= highest_irq_idx_st0_comb;
            mapped_idx_st1 <= mapped_idx_st0_comb;
            is_any_irq_active_st1 <= is_any_irq_active_st0_comb;
        end
    end

    // --- Stage 1: Vector Calculation ---
    // Combinational logic for Stage 1
    logic [31:0] irq_vector_st1_comb;
    logic irq_valid_st1_comb;

    always_comb begin
        // Calculate vector address if any IRQ was active in Stage 0 (indicated by st1 register)
        // The calculation uses the registered mapped_idx from Stage 1 registers
        irq_vector_st1_comb = vector_base_i + (mapped_idx_st1 << 4);
        irq_valid_st1_comb = is_any_irq_active_st1;
    end

    // --- Stage 2: Register Stage 1 Outputs ---
    logic [31:0] irq_vector_st2;
    logic irq_valid_st2;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            irq_vector_st2 <= 32'h0000_0000;
            irq_valid_st2 <= 1'b0;
        end else begin
            irq_vector_st2 <= irq_vector_st1_comb;
            irq_valid_st2 <= irq_valid_st1_comb;
        end
    end

    // --- Output ---
    // Outputs are the registered values from Stage 2
    assign irq_vector_pipe_o = irq_vector_st2;
    assign irq_valid_pipe_o = irq_valid_st2;

endmodule