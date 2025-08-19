//SystemVerilog
module CAN_Transmitter_Config #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 5,
    parameter BIT_TIME = 100
)(
    input clk,
    input rst_n,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] data_in,
    input transmit_en,
    output reg can_tx,
    output reg tx_complete
);
    // The localparam calculation matches the shift_reg size and load data size
    localparam TOTAL_BITS = ADDR_WIDTH + DATA_WIDTH + 3;

    // State registers
    reg [7:0] bit_timer;
    // bit_counter needs to count up to TOTAL_BITS. Assuming TOTAL_BITS < 256.
    reg [7:0] bit_counter;
    reg [TOTAL_BITS-1:0] shift_reg;

    // Pipelined control signals (registered from previous cycle)
    reg timer_not_done_reg;
    reg is_transmitting_reg;

    // Combinational control signals (derived from current state)
    wire timer_not_done = (bit_timer < BIT_TIME-1);
    wire is_transmitting = (bit_counter < TOTAL_BITS);

    // Block 1: Pipelined Control Signal Registration
    // Registers the combinational conditions for use in the next clock cycle.
    // This helps break combinational paths and improve Fmax.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_not_done_reg <= 0;
            is_transmitting_reg <= 0;
        end else begin
            // Register the comparison results from the current cycle
            timer_not_done_reg <= timer_not_done;
            is_transmitting_reg <= is_transmitting;
        end
    end

    // Block 2: Main State Register Updates
    // Updates state based on the pipelined control signals from the previous cycle.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_timer <= 0;
            bit_counter <= 0;
            shift_reg <= 0;
            can_tx <= 0; // Keep original reset value
            tx_complete <= 0;
        end else begin
            // Default assignments
            tx_complete <= 0; // Stays low unless transmission just finished

            // Use buffered signals (from previous cycle) for control flow
            if (timer_not_done_reg) begin // Timer is running
                bit_timer <= bit_timer + 1;
                // No change to other state registers while timer is running
            end else begin // Timer reached BIT_TIME-1 in the previous cycle
                bit_timer <= 0; // Reset timer

                if (is_transmitting_reg) begin // Was transmitting in the previous cycle
                    can_tx <= shift_reg[TOTAL_BITS-1]; // Output current bit
                    shift_reg <= {shift_reg[TOTAL_BITS-2:0], 1'b0}; // Shift register
                    bit_counter <= bit_counter + 1; // Increment bit counter
                end else begin // Was NOT transmitting in the previous cycle (transmission complete or idle)
                    // This state is reached when bit_counter >= TOTAL_BITS in the previous cycle.
                    tx_complete <= 1; // Signal completion for one cycle

                    bit_counter <= 0; // Reset bit counter

                    // Prepare for next transmission if transmit_en is high *in the current cycle*
                    if (transmit_en) begin
                        // Load new data into the shift register
                        shift_reg <= {3'b101, addr, data_in};
                        // can_tx remains at its last state (or reset state 0) until the first bit is transmitted in a future cycle.
                    end
                    // If transmit_en is low, shift_reg keeps its value (likely 0 from reset or previous state).
                end
            end
        end
    end

endmodule