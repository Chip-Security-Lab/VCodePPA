//SystemVerilog
module twos_comp_to_sign_mag (
    input wire [7:0] twos_comp_in,
    output wire [7:0] sign_mag_out
);
    wire sign;
    wire [6:0] magnitude;

    assign sign = twos_comp_in[7];

    // magnitude calculation with simplified Boolean expressions
    wire [6:0] negated_input;

    // For negative input, magnitude = ~twos_comp_in[6:0] + 1
    // Simplify using Boolean algebra: 
    // result[i] = (~twos_comp_in[i] & (|twos_comp_in[i-1:0])) | (twos_comp_in[i] & ~(|twos_comp_in[i-1:0]))
    // For i=0: result[0] = ~twos_comp_in[0] ^ 1'b1 = twos_comp_in[0]
    assign negated_input[0] = twos_comp_in[0];
    assign negated_input[1] = (~twos_comp_in[1] & twos_comp_in[0]) | (twos_comp_in[1] & ~twos_comp_in[0]);
    assign negated_input[2] = (~twos_comp_in[2] & (twos_comp_in[1] | twos_comp_in[0])) | (twos_comp_in[2] & ~(twos_comp_in[1] | twos_comp_in[0]));
    assign negated_input[3] = (~twos_comp_in[3] & (twos_comp_in[2] | twos_comp_in[1] | twos_comp_in[0])) | (twos_comp_in[3] & ~(twos_comp_in[2] | twos_comp_in[1] | twos_comp_in[0]));
    assign negated_input[4] = (~twos_comp_in[4] & (twos_comp_in[3] | twos_comp_in[2] | twos_comp_in[1] | twos_comp_in[0])) | (twos_comp_in[4] & ~(twos_comp_in[3] | twos_comp_in[2] | twos_comp_in[1] | twos_comp_in[0]));
    assign negated_input[5] = (~twos_comp_in[5] & (twos_comp_in[4] | twos_comp_in[3] | twos_comp_in[2] | twos_comp_in[1] | twos_comp_in[0])) | (twos_comp_in[5] & ~(twos_comp_in[4] | twos_comp_in[3] | twos_comp_in[2] | twos_comp_in[1] | twos_comp_in[0]));
    assign negated_input[6] = (~twos_comp_in[6] & (twos_comp_in[5] | twos_comp_in[4] | twos_comp_in[3] | twos_comp_in[2] | twos_comp_in[1] | twos_comp_in[0])) | (twos_comp_in[6] & ~(twos_comp_in[5] | twos_comp_in[4] | twos_comp_in[3] | twos_comp_in[2] | twos_comp_in[1] | twos_comp_in[0]));

    assign magnitude = sign ? negated_input : twos_comp_in[6:0];

    assign sign_mag_out = {sign, magnitude};
endmodule