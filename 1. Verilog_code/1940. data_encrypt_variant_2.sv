//SystemVerilog
module data_encrypt #(parameter DW=16) (
    input clk, en,
    input [DW-1:0] din,
    input [DW-1:0] key,
    output [DW-1:0] dout
);
    // Latch input data and key
    reg [DW-1:0] din_latched;
    reg [DW-1:0] key_latched;

    // Buffer registers for high-fanout signals
    reg [7:0] din_lower_buf1, din_lower_buf2;
    reg [7:0] din_upper_buf1, din_upper_buf2;
    reg [7:0] key_lower_buf1, key_lower_buf2;
    reg [7:0] key_upper_buf1, key_upper_buf2;

    // Buffered signals for a, b, b_invert, sum_group0, sum_group1
    reg [7:0] a_buf1, a_buf2;
    reg [7:0] b_buf1, b_buf2;
    reg [7:0] b_invert_buf1, b_invert_buf2;
    reg [7:0] sum_group0_buf1, sum_group0_buf2;
    reg [7:0] sum_group1_buf1, sum_group1_buf2;

    // Intermediate registers
    reg [7:0] swapped_lower;
    reg [7:0] swapped_upper;
    reg [7:0] subtract_result;
    reg [7:0] add_result;
    reg [DW-1:0] xor_input;
    reg [DW-1:0] xor_input_buf;
    reg [DW-1:0] dout_buf;

    integer i;

    // 8-bit conditional sum subtractor with buffer stages
    function [7:0] conditional_sum_subtractor_buffered;
        input [7:0] a;
        input [7:0] b;
        reg [7:0] b_invert;
        reg [7:0] sum_group0, sum_group1;
        reg carry_group0, carry_group1;
        reg [7:0] sum;
        integer j;
        begin
            // Buffer input a and b
            a_buf1 = a;
            a_buf2 = a_buf1;
            b_buf1 = b;
            b_buf2 = b_buf1;

            // Invert b and buffer
            b_invert = ~b_buf2;
            b_invert_buf1 = b_invert;
            b_invert_buf2 = b_invert_buf1;

            // Calculate sum groups with buffer after each group
            sum_group0[0] = a_buf2[0] ^ b_invert_buf2[0] ^ 1'b1;
            carry_group0 = (a_buf2[0] & b_invert_buf2[0]) | (a_buf2[0] & 1'b1) | (b_invert_buf2[0] & 1'b1);

            sum_group1[0] = a_buf2[0] ^ b_invert_buf2[0] ^ 1'b0;
            carry_group1 = (a_buf2[0] & b_invert_buf2[0]) | (a_buf2[0] & 1'b0) | (b_invert_buf2[0] & 1'b0);

            for (j = 1; j < 8; j = j + 1) begin
                sum_group0[j] = a_buf2[j] ^ b_invert_buf2[j] ^ carry_group0;
                carry_group0 = (a_buf2[j] & b_invert_buf2[j]) | (a_buf2[j] & carry_group0) | (b_invert_buf2[j] & carry_group0);

                sum_group1[j] = a_buf2[j] ^ b_invert_buf2[j] ^ carry_group1;
                carry_group1 = (a_buf2[j] & b_invert_buf2[j]) | (a_buf2[j] & carry_group1) | (b_invert_buf2[j] & carry_group1);
            end

            // Buffer sum groups before selection
            sum_group0_buf1 = sum_group0;
            sum_group0_buf2 = sum_group0_buf1;
            sum_group1_buf1 = sum_group1;
            sum_group1_buf2 = sum_group1_buf1;

            sum = sum_group0_buf2;
            conditional_sum_subtractor_buffered = sum;
        end
    endfunction

    // 8-bit conditional sum adder with buffer stages
    function [7:0] conditional_sum_adder_buffered;
        input [7:0] a;
        input [7:0] b;
        reg [7:0] sum_group0, sum_group1;
        reg carry_group0, carry_group1;
        reg [7:0] sum;
        integer j;
        begin
            // Buffer input a and b
            a_buf1 = a;
            a_buf2 = a_buf1;
            b_buf1 = b;
            b_buf2 = b_buf1;

            // Calculate sum groups with buffer after each group
            sum_group0[0] = a_buf2[0] ^ b_buf2[0] ^ 1'b0;
            carry_group0 = (a_buf2[0] & b_buf2[0]) | (a_buf2[0] & 1'b0) | (b_buf2[0] & 1'b0);

            sum_group1[0] = a_buf2[0] ^ b_buf2[0] ^ 1'b1;
            carry_group1 = (a_buf2[0] & b_buf2[0]) | (a_buf2[0] & 1'b1) | (b_buf2[0] & 1'b1);

            for (j = 1; j < 8; j = j + 1) begin
                sum_group0[j] = a_buf2[j] ^ b_buf2[j] ^ carry_group0;
                carry_group0 = (a_buf2[j] & b_buf2[j]) | (a_buf2[j] & carry_group0) | (b_buf2[j] & carry_group0);

                sum_group1[j] = a_buf2[j] ^ b_buf2[j] ^ carry_group1;
                carry_group1 = (a_buf2[j] & b_buf2[j]) | (a_buf2[j] & carry_group1) | (b_buf2[j] & carry_group1);
            end

            // Buffer sum groups before selection
            sum_group0_buf1 = sum_group0;
            sum_group0_buf2 = sum_group0_buf1;
            sum_group1_buf1 = sum_group1;
            sum_group1_buf2 = sum_group1_buf1;

            sum = sum_group0_buf2;
            conditional_sum_adder_buffered = sum;
        end
    endfunction

    // Latch input data and key, and buffer for high-fanout paths
    always @(posedge clk) begin
        if (en) begin
            din_latched <= din;
            key_latched <= key;

            din_lower_buf1 <= din[7:0];
            din_lower_buf2 <= din_lower_buf1;
            din_upper_buf1 <= din[15:8];
            din_upper_buf2 <= din_upper_buf1;

            key_lower_buf1 <= key[7:0];
            key_lower_buf2 <= key_lower_buf1;
            key_upper_buf1 <= key[15:8];
            key_upper_buf2 <= key_upper_buf1;
        end
    end

    // Combinational logic with buffer stages for high-fanout signals
    always @(*) begin
        // Byte swap with buffered signals
        swapped_lower = din_lower_buf2;
        swapped_upper = din_upper_buf2;

        // Subtraction with buffered conditional sum subtractor
        subtract_result = conditional_sum_subtractor_buffered(swapped_lower, swapped_upper);

        // Addition with buffered conditional sum adder
        add_result = conditional_sum_adder_buffered(swapped_upper, swapped_lower);

        // Buffer the XOR input before output
        xor_input = {subtract_result, add_result};
        xor_input_buf = xor_input;

        // Buffer the final output
        dout_buf = xor_input_buf ^ {key_upper_buf2, key_lower_buf2};
    end

    assign dout = dout_buf;

endmodule