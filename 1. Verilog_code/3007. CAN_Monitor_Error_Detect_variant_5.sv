//SystemVerilog
module CAN_Monitor_Error_Detect #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input can_rx,
    input can_tx,
    output reg form_error,
    output reg ack_error,
    output reg crc_error
);
    // Original state registers
    reg [6:0] bit_counter;
    reg [14:0] crc_calc;
    reg [14:0] crc_received;

    // Pipeline registers for error conditions removed via retiming
    // The logic driving these conditions is now registered directly at the output
    // reg ack_condition_r;
    // reg crc_condition_r;

    // Optimized comparison signals based on current bit_counter value (before increment)
    // These signals are combinational and represent the value of bit_counter at the start of the cycle
    wire is_bit_95;
    wire is_bit_96;
    wire is_bit_97;

    // Factored comparison logic to potentially share hardware
    // 95 = 7'b1011111
    // 96 = 7'b1100000
    // 97 = 7'b1100001
    wire msb_match = bit_counter[6]; // bit_counter[6] is 1 for 95, 96, 97
    wire bit5_is_0 = ~bit_counter[5]; // bit_counter[5] is 0 for 95
    wire bit5_is_1 = bit_counter[5]; // bit_counter[5] is 1 for 96, 97
    wire lower_bits_zeros_4_to_1 = ~bit_counter[4] & ~bit_counter[3] & ~bit_counter[2] & ~bit_counter[1]; // Common for 96, 97

    assign is_bit_95 = msb_match & bit5_is_0 & bit_counter[4] & bit_counter[3] & bit_counter[2] & bit_counter[1] & bit_counter[0];
    assign is_bit_96 = msb_match & bit5_is_1 & lower_bits_zeros_4_to_1 & ~bit_counter[0];
    assign is_bit_97 = msb_match & bit5_is_1 & lower_bits_zeros_4_to_1 & bit_counter[0];


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset original state
            bit_counter <= 0;
            crc_calc <= 0;
            crc_received <= 0;

            // Reset output registers
            form_error <= 0;
            ack_error <= 0;
            crc_error <= 0;

            // Reset pipeline registers (removed via retiming)
            // ack_condition_r <= 0;
            // crc_condition_r <= 0;
        end else begin
            // Update bit counter
            // This non-blocking assignment is evaluated using the value of bit_counter at the start of the cycle
            // and updates at the end of the cycle.
            bit_counter <= bit_counter + 1;

            // CRC calculation
            // This logic directly updates crc_calc based on its previous value and input can_rx
            crc_calc <= {crc_calc[13:0], 1'b0} ^
                       ((crc_calc[14] ^ can_rx) ? 15'h4599 : 15'h0);

            // Update crc_received based on bit_counter reaching 95
            // This condition uses the value of bit_counter *before* the increment in this cycle (via is_bit_95 wire)
            if (is_bit_95) begin
                crc_received <= {crc_received[13:0], can_rx};
            end

            // Update form_error directly (simple logic, no dependency on high-fanout signals)
            form_error <= (can_rx && can_tx);

            // Update ack_error and crc_error by registering the conditions directly
            // This effectively moves the output registers backward across the logic
            // that previously fed the intermediate pipeline registers (ack_condition_r, crc_condition_r)
            // The conditions depend on the *old* values of bit_counter (via is_bit_96, is_bit_97 wires), crc_calc, and crc_received
            // The results are registered directly into the output registers, removing the intermediate stage
            ack_error <= is_bit_96 && !can_tx;
            crc_error <= is_bit_97 && (crc_calc != crc_received);
        end
    end

endmodule