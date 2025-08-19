module dadda_adder (
    input  [3:0] a, b,
    output [3:0] sum
);
    wire [3:0] temp_sum;
    wire [3:0] temp_carry;

    assign temp_sum = a ^ b;
    assign temp_carry = a & b;

    assign sum = temp_sum + temp_carry;
endmodule