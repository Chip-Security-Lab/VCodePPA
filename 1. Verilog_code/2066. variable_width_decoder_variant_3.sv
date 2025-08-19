//SystemVerilog
module variable_width_decoder #(
    parameter IN_WIDTH = 3,
    parameter OUT_SEL = 2
) (
    input wire [IN_WIDTH-1:0] encoded_in,
    input wire [OUT_SEL-1:0] width_sel,
    output reg [(2**IN_WIDTH)-1:0] decoded_out
);
    wire [4:0] output_width;
    assign output_width = (5'd1 << width_sel);

    // Condition-Sum Subtractor for 5-bit: result = a - b
    function [4:0] conditional_sum_sub_5bit;
        input [4:0] a;
        input [4:0] b;
        reg [4:0] b_inverted;
        reg carry_in;
        reg [4:0] sum0, sum1;
        reg carry0, carry1;
        integer i;
        begin
            // Two possible carry-in values: 0 and 1
            b_inverted = ~b;
            // carry_in = 1 for subtraction (two's complement)
            carry_in = 1'b1;

            // Calculate sum with carry_in = 0
            sum0[0] = a[0] ^ b_inverted[0];
            carry0 = a[0] & b_inverted[0];
            for (i = 1; i < 5; i = i + 1) begin
                sum0[i] = a[i] ^ b_inverted[i] ^ carry0;
                carry0 = (a[i] & b_inverted[i]) | (a[i] & carry0) | (b_inverted[i] & carry0);
            end

            // Calculate sum with carry_in = 1
            sum1[0] = a[0] ^ b_inverted[0] ^ carry_in;
            carry1 = (a[0] & b_inverted[0]) | (a[0] & carry_in) | (b_inverted[0] & carry_in);
            for (i = 1; i < 5; i = i + 1) begin
                sum1[i] = a[i] ^ b_inverted[i] ^ carry1;
                carry1 = (a[i] & b_inverted[i]) | (a[i] & carry1) | (b_inverted[i] & carry1);
            end

            // Select the appropriate sum based on carry_in (always 1 for subtraction)
            conditional_sum_sub_5bit = sum1;
        end
    endfunction

    reg [4:0] decode_index;
    integer i;

    always @(*) begin
        decoded_out = {(2**IN_WIDTH){1'b0}};
        // Default decode_index
        decode_index = 5'd0;
        case (width_sel)
            2'd0: decode_index = {4'd0, encoded_in[0]};
            2'd1: decode_index = {3'd0, encoded_in[1:0]};
            2'd2: decode_index = {2'd0, encoded_in[2:0]};
            2'd3: decode_index = {encoded_in[IN_WIDTH-1:0]};
            default: decode_index = 5'd0;
        endcase

        // Use conditional-sum subtractor to calculate position
        for (i = 0; i < (2**IN_WIDTH); i = i + 1) begin
            if (conditional_sum_sub_5bit(decode_index, i[4:0]) == 5'd0)
                decoded_out[i] = 1'b1;
            else
                decoded_out[i] = 1'b0;
        end
    end
endmodule