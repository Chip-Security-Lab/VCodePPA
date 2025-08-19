//SystemVerilog
module PriorityIVMU (
    input wire clk,
    input wire rst,
    input wire [15:0] irq_in,
    input wire [31:0] prog_addr,
    input wire [3:0] prog_idx,
    input wire prog_we,
    output reg [31:0] isr_addr,
    output reg irq_valid
);

    reg [31:0] vectors[15:0];
    integer i;

    // Combinational logic for next state calculation
    reg [31:0] next_isr_addr;
    reg next_irq_valid;

    always @(*) begin
        // Calculate next_irq_valid (reduction OR)
        next_irq_valid = |irq_in;

        // Calculate next_isr_addr based on priority (lowest index wins)
        // Optimized priority encoder using a loop
        next_isr_addr = 32'h0; // Default value when no interrupt is asserted

        // Iterate from highest index down to lowest index.
        // The last assignment will be for the lowest index i where irq_in[i] is high.
        for (i = 15; i >= 0; i = i - 1) begin
            if (irq_in[i]) begin
                next_isr_addr = vectors[i];
            end
        end
    end

    // Synchronous logic for state updates
    always @(posedge clk) begin
        if (rst) begin
            irq_valid <= 1'b0;
            isr_addr <= 32'h0;
            // Initialize vectors memory
            for (i = 0; i < 16; i = i + 1) begin
                vectors[i] <= 32'h0;
            end
        end else begin
            // Handle vector programming
            if (prog_we) begin
                vectors[prog_idx] <= prog_addr;
            end

            // Update outputs based on combinational logic when not programming
            // Note: The original code updates isr_addr/irq_valid only when !prog_we
            // We maintain this behavior.
            if (!prog_we) begin
                 irq_valid <= next_irq_valid;
                 isr_addr <= next_isr_addr;
            end
            // If prog_we is high, isr_addr and irq_valid hold their previous values
            // This matches the original code's structure where the else branch is skipped.
        end
    end

endmodule