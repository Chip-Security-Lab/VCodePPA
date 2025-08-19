//SystemVerilog
module TimeSlicedIVMU (
    input clk, rst,
    input [15:0] irq_in,
    input [3:0] time_slice,
    output reg [31:0] vector_addr,
    output reg irq_out
);
    reg [31:0] vector_table [0:15];
    reg [3:0] current_slice; // This register is not part of the critical path being optimized, keep it as is.
    integer i; // Used in initial block

    // --- Initial block for memory initialization ---
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            vector_table[i] = 32'hC000_0000 + (i << 6);
        end
    end

    // --- Stage 1: Combinational Logic ---
    // Check if the IRQ bit at the current time_slice is set
    // This is equivalent to the original logic (irq_in & (1<<time_slice)) != 0
    wire irq_condition_s1;
    assign irq_condition_s1 = irq_in[time_slice]; // Optimized logic

    // The vector index is simply the time_slice if the condition is met.
    // The memory lookup happens regardless, but the output update is conditional.
    wire [3:0] vector_index_s1;
    assign vector_index_s1 = time_slice; // Optimized logic

    // Lookup vector address based on index (which is time_slice)
    wire [31:0] vector_addr_next_s1;
    assign vector_addr_next_s1 = vector_table[vector_index_s1]; // Uses vector_index_s1 (which is time_slice)

    // --- Stage 2: Pipelined Registers ---
    // Registers to hold Stage 1 results for one clock cycle
    reg irq_condition_reg;
    reg [31:0] vector_addr_next_reg;

    // --- Stage 3: Output Register Updates (using Stage 2 results) ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_slice <= 4'h0; // Keep this register
            irq_out <= 1'b0;
            vector_addr <= 32'h0; // Initialize vector_addr explicitly
            irq_condition_reg <= 1'b0;
            vector_addr_next_reg <= 32'h0;
        end else begin
            // Update current_slice (not pipelined with the main path)
            current_slice <= time_slice;

            // Register Stage 1 outputs
            irq_condition_reg <= irq_condition_s1;
            vector_addr_next_reg <= vector_addr_next_s1;

            // Update final outputs using registered Stage 1 results
            irq_out <= irq_condition_reg; // irq_out is delayed by 1 cycle
            if (irq_condition_reg) begin // Update vector_addr only if irq_condition was true in the previous cycle
                vector_addr <= vector_addr_next_reg;
            end
            // If irq_condition_reg is false, vector_addr holds its value, matching original behavior.
        end
    end

endmodule