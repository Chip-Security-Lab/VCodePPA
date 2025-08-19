//SystemVerilog
module twos_comp_to_sign_mag (
    input  wire [7:0] twos_comp_in,
    output wire [7:0] sign_mag_out
);
    wire sign_bit;
    wire [6:0] input_magnitude;
    wire [6:0] magnitude_cond_sum;

    assign sign_bit = twos_comp_in[7];
    assign input_magnitude = twos_comp_in[6:0];

    // Conditional Sum Subtractor: magnitude = sign_bit ? (0 - input_magnitude) : input_magnitude;
    wire [6:0] negated_input;
    wire [6:0] sum_stage0, sum_stage1, sum_stage2;
    wire carry0, carry1, carry2, carry3, carry4, carry5, carry6;
    wire [6:0] mux_sum0, mux_sum1, mux_sum2;

    // Stage 0: Bit 0
    assign sum_stage0[0] = input_magnitude[0] ^ 1'b1; // ~input_magnitude[0]
    assign carry0 = sign_bit & input_magnitude[0];
    assign mux_sum0[0] = sign_bit ? sum_stage0[0] : input_magnitude[0];

    // Stage 1: Bit 1
    assign sum_stage0[1] = input_magnitude[1] ^ 1'b1; // ~input_magnitude[1]
    assign sum_stage1[1] = sum_stage0[1] ^ carry0;
    assign carry1 = (sign_bit & input_magnitude[1]) | (sum_stage0[1] & carry0);
    assign mux_sum0[1] = sign_bit ? sum_stage1[1] : input_magnitude[1];

    // Stage 2: Bit 2
    assign sum_stage0[2] = input_magnitude[2] ^ 1'b1;
    assign sum_stage1[2] = sum_stage0[2] ^ carry1;
    assign carry2 = (sign_bit & input_magnitude[2]) | (sum_stage0[2] & carry1);
    assign mux_sum0[2] = sign_bit ? sum_stage1[2] : input_magnitude[2];

    // Stage 3: Bit 3
    assign sum_stage0[3] = input_magnitude[3] ^ 1'b1;
    assign sum_stage1[3] = sum_stage0[3] ^ carry2;
    assign carry3 = (sign_bit & input_magnitude[3]) | (sum_stage0[3] & carry2);
    assign mux_sum0[3] = sign_bit ? sum_stage1[3] : input_magnitude[3];

    // Stage 4: Bit 4
    assign sum_stage0[4] = input_magnitude[4] ^ 1'b1;
    assign sum_stage1[4] = sum_stage0[4] ^ carry3;
    assign carry4 = (sign_bit & input_magnitude[4]) | (sum_stage0[4] & carry3);
    assign mux_sum0[4] = sign_bit ? sum_stage1[4] : input_magnitude[4];

    // Stage 5: Bit 5
    assign sum_stage0[5] = input_magnitude[5] ^ 1'b1;
    assign sum_stage1[5] = sum_stage0[5] ^ carry4;
    assign carry5 = (sign_bit & input_magnitude[5]) | (sum_stage0[5] & carry4);
    assign mux_sum0[5] = sign_bit ? sum_stage1[5] : input_magnitude[5];

    // Stage 6: Bit 6
    assign sum_stage0[6] = input_magnitude[6] ^ 1'b1;
    assign sum_stage1[6] = sum_stage0[6] ^ carry5;
    assign carry6 = (sign_bit & input_magnitude[6]) | (sum_stage0[6] & carry5);
    assign mux_sum0[6] = sign_bit ? sum_stage1[6] : input_magnitude[6];

    assign magnitude_cond_sum = mux_sum0;

    assign sign_mag_out = {sign_bit, magnitude_cond_sum};

endmodule