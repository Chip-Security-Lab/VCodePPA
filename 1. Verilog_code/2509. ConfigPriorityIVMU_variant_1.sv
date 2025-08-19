//SystemVerilog
module ConfigPriorityIVMU (
    input clk,
    input reset,
    input [7:0] irq_in,
    input [2:0] priority_cfg [0:7],
    input update_pri,
    output reg [31:0] isr_addr,
    output reg irq_out
);

    reg [31:0] vector_table [0:7];
    reg [2:0] priorities [0:7];
    reg [2:0] highest_pri;
    reg [2:0] highest_idx;
    integer i;

    // Initialize vector table and default priorities
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            vector_table[i] = 32'h7000_0000 + (i * 64);
            priorities[i] = i; // Default priority is index
        end
    end

    // Clocked logic for priority updates and IRQ processing
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset state
            for (i = 0; i < 8; i = i + 1) begin
                priorities[i] <= i; // Reset priorities to default
            end
            irq_out <= 0;
            highest_pri <= 3'h7; // Reset highest priority
            highest_idx <= 3'h0; // Reset highest index
            isr_addr <= vector_table[0]; // Reset ISR address (can be any default)
        end else if (update_pri) begin // !reset && update_pri
            // Update priorities
            for (i = 0; i < 8; i = i + 1) begin
                priorities[i] <= priority_cfg[i];
            end
            // Keep other outputs stable when updating priorities
            irq_out <= irq_out;
            isr_addr <= isr_addr;
            highest_pri <= highest_pri;
            highest_idx <= highest_idx;
        end else begin // !reset && !update_pri (Process IRQs)
            // Calculate next state values using temporary variables
            reg [2:0] calculated_highest_pri = 3'h7;
            reg [2:0] calculated_highest_idx = 3'h0;
            reg calculated_irq_out = 0;
            reg [31:0] calculated_isr_addr = isr_addr; // Default to retaining current ISR address if no IRQ is found

            // Iterate through IRQ inputs to find the highest priority asserted IRQ
            // Using blocking assignments for calculation within the loop
            for (i = 0; i < 8; i = i + 1) begin
                if (irq_in[i] && priorities[i] < calculated_highest_pri) begin
                    calculated_highest_pri = priorities[i]; // Update highest priority found so far
                    calculated_highest_idx = i[2:0];      // Update index of highest priority IRQ
                    calculated_irq_out = 1;               // Assert IRQ output
                    calculated_isr_addr = vector_table[i]; // Update ISR address
                end
            end

            // Assign calculated values to registers using non-blocking assignments
            highest_pri <= calculated_highest_pri;
            highest_idx <= calculated_highest_idx;
            irq_out <= calculated_irq_out;
            isr_addr <= calculated_isr_addr;
            // priorities array is not updated in this branch.
        end
    end

endmodule