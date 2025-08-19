//SystemVerilog
module decimal_ascii_to_binary #(parameter MAX_DIGITS=3)(
    input wire [8*MAX_DIGITS-1:0] ascii_in,
    output reg [$clog2(10**MAX_DIGITS)-1:0] binary_out,
    output reg valid
);
    integer i;
    reg signed [3:0] digit_signed;
    reg signed [$clog2(10**MAX_DIGITS)+3:0] mult_result;
    reg signed [$clog2(10**MAX_DIGITS)-1:0] binary_acc;
    reg valid_internal;

    // Signed 4-bit x 4-bit multiplier: Baugh-Wooley algorithm
    function signed [7:0] baugh_wooley_mult4;
        input signed [3:0] a;
        input signed [3:0] b;
        reg [3:0] a_unsigned;
        reg [3:0] b_unsigned;
        reg [7:0] partial_products [0:3];
        reg [7:0] sum_partial;
        integer j;
        begin
            a_unsigned = a[3:0];
            b_unsigned = b[3:0];

            // Partial product generation
            partial_products[0] = {4'b0, a_unsigned & {4{b_unsigned[0]}}};
            partial_products[1] = {3'b0, a_unsigned & {4{b_unsigned[1]}}, 1'b0};
            partial_products[2] = {2'b0, a_unsigned & {4{b_unsigned[2]}}, 2'b0};
            partial_products[3] = {1'b0, a_unsigned & {4{b_unsigned[3]}}, 3'b0};

            // Correction bits for sign (Baugh-Wooley)
            // For 4x4 signed:
            // Add 'a' if b[3] (MSB of b) is set
            // Add 'b' if a[3] (MSB of a) is set
            // Add 1 to bit 7 if both a[3] and b[3] are set

            sum_partial = partial_products[0] + partial_products[1] + partial_products[2] + partial_products[3];

            // Correction for a negative
            if (a[3])
                sum_partial = sum_partial + {b_unsigned, 4'b0};

            // Correction for b negative
            if (b[3])
                sum_partial = sum_partial + {a_unsigned, 4'b0};

            // Correction for both negative
            if (a[3] && b[3])
                sum_partial = sum_partial + 8'b1000_0000; // Add 1 to MSB

            // Two's complement correction for negative partials
            if (a[3])
                sum_partial = sum_partial - (8'b0001_0000); // Subtract 1 << 4
            if (b[3])
                sum_partial = sum_partial - (8'b0001_0000); // Subtract 1 << 4

            baugh_wooley_mult4 = sum_partial;
        end
    endfunction

    always @* begin
        binary_acc = 0;
        valid_internal = 1;
        for (i = 0; i < MAX_DIGITS; i = i + 1) begin
            digit_signed = ascii_in[8*i +: 8] - 8'sd48;
            if (digit_signed <= 9 && digit_signed >= 0) begin
                // Multiply by 10 using Baugh-Wooley signed multiplier
                mult_result = baugh_wooley_mult4({{($clog2(10**MAX_DIGITS)-4){binary_acc[$clog2(10**MAX_DIGITS)-1]}}, binary_acc[3:0]}, 4'sd10);
                binary_acc = mult_result[$clog2(10**MAX_DIGITS)-1:0] + digit_signed;
            end else if (ascii_in[8*i +: 8] != 8'h20) begin
                valid_internal = 0;
            end
        end
        binary_out = binary_acc;
        valid = valid_internal;
    end
endmodule