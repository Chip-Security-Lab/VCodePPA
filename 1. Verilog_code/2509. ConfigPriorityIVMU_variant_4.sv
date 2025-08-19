//SystemVerilog
module ConfigPriorityIVMU_req_ack (
    input clk,
    input reset,
    input [7:0] irq_in,
    input [2:0] priority_cfg [0:7],
    input update_pri,
    input isr_ack, // New: Acknowledge signal from receiver
    output reg [31:0] isr_addr, // Data output
    output reg isr_req // Request signal (valid)
);

    reg [31:0] vector_table [0:7];
    reg [2:0] priorities [0:7];
    reg [2:0] highest_pri_comb, highest_idx_comb; // Combinational search result
    reg interrupt_found_comb; // Flag if any interrupt is found combinatorially

    // State machine for Req-Ack handshake
    parameter STATE_IDLE = 1'b0;
    parameter STATE_REQ_ASSERTED = 1'b1;
    reg current_state;

    integer i;

    // Initialize vector table
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            vector_table[i] = 32'h7000_0000 + (i * 64);
        end
    end

    // Combinational logic to find highest priority interrupt
    // This logic runs continuously to find the *currently* highest priority active interrupt
    always @(*) begin
        highest_pri_comb = 3'h7; // Lower value means higher priority (7 is lowest priority value)
        highest_idx_comb = 3'h0;
        interrupt_found_comb = 0;

        // Find the highest priority interrupt among active interrupts
        for (i = 0; i < 8; i = i + 1) begin
            if (irq_in[i] && priorities[i] < highest_pri_comb) begin
                highest_pri_comb = priorities[i];
                highest_idx_comb = i[2:0];
                interrupt_found_comb = 1;
            end
        end
    end

    // Sequential logic for state, priorities, and outputs
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset state
            current_state <= STATE_IDLE;
            isr_req <= 0;
            isr_addr <= 0; // Clear data on reset

            // Reset priorities
            for (i = 0; i < 8; i = i + 1) priorities[i] <= i; // Default priorities

        end else if (update_pri) begin
            // Priority update takes precedence and resets handshake
            current_state <= STATE_IDLE;
            isr_req <= 0;
            isr_addr <= 0; // Clear data when updating priorities

            // Update priorities
            for (i = 0; i < 8; i = i + 1) priorities[i] <= priority_cfg[i];

        end else begin // Normal operation (not reset, not update_pri)
            case (current_state)
                STATE_IDLE: begin
                    // If an interrupt is found combinatorially
                    if (interrupt_found_comb) begin
                        current_state <= STATE_REQ_ASSERTED;
                        isr_req <= 1;
                        isr_addr <= vector_table[highest_idx_comb]; // Register the address
                    end else begin
                        // Stay in IDLE, req remains low, addr remains 0
                        current_state <= STATE_IDLE;
                        isr_req <= 0;
                        isr_addr <= 0;
                    end
                end
                STATE_REQ_ASSERTED: begin
                    // If acknowledged by receiver
                    if (isr_ack) begin
                        current_state <= STATE_IDLE;
                        isr_req <= 0; // Deassert req
                        isr_addr <= 0; // Clear data after handshake
                    end else begin
                        // Wait for ack, hold req and addr
                        current_state <= STATE_REQ_ASSERTED;
                        // isr_req holds 1
                        // isr_addr holds its value
                    end
                end
            endcase
        end
    end

endmodule