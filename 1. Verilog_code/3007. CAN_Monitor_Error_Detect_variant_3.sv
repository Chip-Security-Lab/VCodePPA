//SystemVerilog
module CAN_Monitor_Error_Detect #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input can_rx,
    input can_tx,
    output reg form_error, // Pipelined output
    output reg ack_error,  // Pipelined output
    output reg crc_error   // Pipelined output
);
    reg [6:0] bit_counter;
    reg [14:0] crc_calc;
    reg [14:0] crc_received;

    // Combinational logic for bit_counter increment using parallel prefix (incrementer) structure
    // This implements bit_counter + 1 using carry-lookahead principles for increment
    wire [6:0] bit_counter_next;
    wire [5:0] carries_into_bits_1_to_6; // carries_into_bits_1_to_6[i] is the carry into bit i+1

    // Calculate carries into bits 1 through 6 using prefix ANDs
    assign carries_into_bits_1_to_6[0] = bit_counter[0];
    assign carries_into_bits_1_to_6[1] = bit_counter[1] & bit_counter[0];
    assign carries_into_bits_1_to_6[2] = bit_counter[2] & bit_counter[1] & bit_counter[0];
    assign carries_into_bits_1_to_6[3] = bit_counter[3] & bit_counter[2] & bit_counter[1] & bit_counter[0];
    assign carries_into_bits_1_to_6[4] = bit_counter[4] & bit_counter[3] & bit_counter[2] & bit_counter[1] & bit_counter[0];
    assign carries_into_bits_1_to_6[5] = bit_counter[5] & bit_counter[4] & bit_counter[3] & bit_counter[2] & bit_counter[1] & bit_counter[0];

    // Calculate sum bits
    assign bit_counter_next[0] = ~bit_counter[0];
    assign bit_counter_next[1] = bit_counter[1] ^ carries_into_bits_1_to_6[0];
    assign bit_counter_next[2] = bit_counter[2] ^ carries_into_bits_1_to_6[1];
    assign bit_counter_next[3] = bit_counter[3] ^ carries_into_bits_1_to_6[2];
    assign bit_counter_next[4] = bit_counter[4] ^ carries_into_bits_1_to_6[3];
    assign bit_counter_next[5] = bit_counter[5] ^ carries_into_bits_1_to_6[4];
    assign bit_counter_next[6] = bit_counter[6] ^ carries_into_bits_1_to_6[5];

    // Combinational logic for error conditions (potential critical paths)
    wire form_condition = (can_rx && can_tx);
    wire ack_condition = (bit_counter == 96) && !can_tx;
    wire crc_condition = (bit_counter == 97) && (crc_calc != crc_received);

    // Pipeline registers for error outputs
    reg form_error_pipe;
    reg ack_error_pipe;
    reg crc_error_pipe;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 0;
            crc_calc <= 0;
            crc_received <= 0;
            // Reset pipeline registers
            form_error_pipe <= 0;
            ack_error_pipe <= 0;
            crc_error_pipe <= 0;
            // Reset outputs (will take value from pipe registers next cycle)
            form_error <= 0;
            ack_error <= 0;
            crc_error <= 0;
        end else begin
            // Update state elements
            bit_counter <= bit_counter_next;

            // CRC calculation
            crc_calc <= {crc_calc[13:0], 1'b0} ^
                       ((crc_calc[14] ^ can_rx) ? 15'h4599 : 15'h0);

            // Update crc_received at a specific counter value
            // This comparison uses the bit_counter value *before* the increment in this cycle
            if (bit_counter == 95) crc_received <= {crc_received[13:0], can_rx};

            // Pipeline stage: Register the combinational error conditions
            // These conditions are calculated based on the state at the beginning of the current cycle
            form_error_pipe <= form_condition;
            ack_error_pipe <= ack_condition;
            crc_error_pipe <= crc_condition;

            // Assign pipelined results to outputs
            // Outputs are delayed by one cycle relative to the original logic
            form_error <= form_error_pipe;
            ack_error <= ack_error_pipe;
            crc_error <= crc_error_pipe;
        end
    end
endmodule