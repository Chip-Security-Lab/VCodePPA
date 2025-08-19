//SystemVerilog
module decimal_ascii_to_binary #(parameter MAX_DIGITS=3)(
    input wire [8*MAX_DIGITS-1:0] ascii_in,
    output reg [$clog2(10**MAX_DIGITS)-1:0] binary_out,
    output reg valid
);

    integer i;
    reg [3:0] digit;
    reg [$clog2(10**MAX_DIGITS)-1:0] temp_result;
    reg [$clog2(10**MAX_DIGITS)-1:0] karatsuba_mul_result;

    // 4-bit Karatsuba multiplier
    function [7:0] karatsuba_4bit_mul;
        input [3:0] a, b;
        reg [1:0] a_high, a_low, b_high, b_low;
        reg [3:0] z0, z1, z2;
        reg [3:0] t1, t2;
        begin
            a_high = a[3:2];
            a_low  = a[1:0];
            b_high = b[3:2];
            b_low  = b[1:0];

            z0 = a_low * b_low;
            z2 = a_high * b_high;
            t1 = a_low + a_high;
            t2 = b_low + b_high;
            z1 = t1 * t2 - z0 - z2;

            karatsuba_4bit_mul = {z2, 4'b0} + {z1, 2'b0} + z0;
        end
    endfunction

    always @* begin
        binary_out = 0;
        valid = 1;
        temp_result = 0;

        for (i = 0; i < MAX_DIGITS; i = i + 1) begin
            digit = ascii_in[8*i+:8] - 8'h30;

            if (digit <= 9) begin
                // Multiply by 10 using Karatsuba: temp_result * 10
                karatsuba_mul_result = karatsuba_4bit_mul(temp_result[3:0], 4'd10);
                binary_out = karatsuba_mul_result + digit;
                temp_result = binary_out;
            end else if (ascii_in[8*i+:8] != 8'h20) begin
                valid = 0;
            end
        end
    end

endmodule