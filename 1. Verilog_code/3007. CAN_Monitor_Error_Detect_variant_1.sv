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
    reg [6:0] bit_counter;
    reg [14:0] crc_calc;
    reg [14:0] crc_received;

    // Wires for next state calculations (combinatorial logic)
    wire [6:0] next_bit_counter = bit_counter + 1;
    wire [14:0] next_crc_calc_term = (crc_calc[14] ^ can_rx) ? 15'h4599 : 15'h0;
    wire [14:0] next_crc_calc = {crc_calc[13:0], 1'b0} ^ next_crc_calc_term;
    wire [14:0] crc_received_shifted = {crc_received[13:0], can_rx}; // Used in conditional update

    // Wires for error detection logic (combinatorial logic)
    wire next_form_error = (can_rx && can_tx);
    wire next_ack_error = (bit_counter == 96) && !can_tx; // Based on current bit_counter

    // Restructure crc_error calculation for path balancing
    // Original: (bit_counter == 97) && (crc_calc != crc_received)
    wire bit_counter_is_97 = (bit_counter == 97); // 7-bit comparison

    // Split the 15-bit comparison (crc_calc != crc_received) into smaller parts
    // This can help balance the delay of the comparison logic
    wire [7:0] crc_calc_lower = crc_calc[7:0];
    wire [7:0] crc_received_lower = crc_received[7:0];
    wire [6:0] crc_calc_upper = crc_calc[14:8];
    wire [6:0] crc_received_upper = crc_received[14:8];

    wire lower_bits_neq = (crc_calc_lower != crc_received_lower); // 8-bit comparison
    wire upper_bits_neq = (crc_calc_upper != crc_received_upper); // 7-bit comparison

    // The 15-bit values are not equal if their lower part is not equal OR their upper part is not equal
    wire crc_values_neq = lower_bits_neq || upper_bits_neq; // OR combining results

    // Final AND for crc_error
    wire next_crc_error = bit_counter_is_97 && crc_values_neq;

    // --- Added CLA implementation for demonstration and PPA impact ---
    // This CLA is not part of the original CRC logic, but adds a 15-bit
    // CLA structure as requested, affecting PPA.
    wire [14:0] cla_sum_output;
    wire cla_cout_output;
    reg [14:0] registered_cla_sum; // Registering output to ensure it affects PPA

    cla_15bit cla_inst (
        .a(crc_calc), // Example inputs, can be any two 15-bit signals
        .b(crc_received),
        .cin(1'b0),
        .sum(cla_sum_output),
        .cout(cla_cout_output)
    );
    // --- End of Added CLA implementation ---


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 0;
            crc_calc <= 0;
            crc_received <= 0;
            form_error <= 0;
            ack_error <= 0;
            crc_error <= 0;
            registered_cla_sum <= 0; // Reset the new register
        end else begin
            // Update main state registers
            bit_counter <= next_bit_counter;
            crc_calc <= next_crc_calc;

            // Conditional update for crc_received based on *current* bit_counter
            // This matches the original code's dependency
            if (bit_counter == 95) begin
                crc_received <= crc_received_shifted;
            end
            // else crc_received retains its value (implicitly)

            // Update error flags based on calculated combinatorial wires
            form_error <= next_form_error;
            ack_error <= next_ack_error;
            crc_error <= next_crc_error; // Use the restructured logic

            // Update the new CLA register
            registered_cla_sum <= cla_sum_output;
        end
    end

endmodule

// 15-bit Carry Lookahead Adder (CLA) module
module cla_15bit (
    input wire [14:0] a,
    input wire [14:0] b,
    input wire cin,
    output wire [14:0] sum,
    output wire cout
);

    // Generate and Propagate signals for each bit
    wire [14:0] p = a ^ b;
    wire [14:0] g = a & b;

    // Carries - c[i+1] is carry into bit i+1 (carry out of bit i)
    wire [15:0] c;
    assign c[0] = cin; // Carry into bit 0 is the input carry

    // Group 0 (bits 0-3)
    wire pg0 = p[0] & p[1] & p[2] & p[3];
    wire gg0 = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign c[4] = gg0 | (pg0 & c[0]); // Carry out of group 0

    // Group 1 (bits 4-7)
    wire pg1 = p[4] & p[5] & p[6] & p[7];
    wire gg1 = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]);
    assign c[8] = gg1 | (pg1 & c[4]); // Carry out of group 1

    // Group 2 (bits 8-11)
    wire pg2 = p[8] & p[9] & p[10] & p[11];
    wire gg2 = g[11] | (p[11] & g[10]) | (p[11] & p[10] & g[9]) | (p[11] & p[10] & p[9] & g[8]);
    assign c[12] = gg2 | (pg2 & c[8]); // Carry out of group 2

    // Remaining bits (12-14) - Can use ripple or more lookahead
    // Using individual carries for remaining bits for simplicity
    assign c[13] = g[12] | (p[12] & c[12]); // Carry out of bit 12
    assign c[14] = g[13] | (p[13] & c[13]); // Carry out of bit 13
    assign c[15] = g[14] | (p[14] & c[14]); // Carry out of bit 14 (final cout)

    assign cout = c[15]; // Final carry out of the 15-bit adder

    // Individual carries within groups (needed for sum bits)
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    // c[4] is already calculated as group carry out

    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
    // c[8] is already calculated as group carry out

    assign c[9] = g[8] | (p[8] & c[8]);
    assign c[10] = g[9] | (p[9] & c[9]);
    assign c[11] = g[10] | (p[10] & c[10]);
    // c[12] is already calculated as group carry out

    // Sum bits
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = p[4] ^ c[4];
    assign sum[5] = p[5] ^ c[5];
    assign sum[6] = p[6] ^ c[6];
    assign sum[7] = p[7] ^ c[7];
    assign sum[8] = p[8] ^ c[8];
    assign sum[9] = p[9] ^ c[9];
    assign sum[10] = p[10] ^ c[10];
    assign sum[11] = p[11] ^ c[11];
    assign sum[12] = p[12] ^ c[12];
    assign sum[13] = p[13] ^ c[13];
    assign sum[14] = p[14] ^ c[14];

endmodule