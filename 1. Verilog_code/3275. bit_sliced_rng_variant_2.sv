//SystemVerilog
module bit_sliced_rng (
    input  wire        clk_i,
    input  wire        rst_n_i,
    output wire [31:0] rnd_o
);

    // Internal register declarations (state)
    reg [7:0] slice_reg0_q;
    reg [7:0] slice_reg1_q;
    reg [7:0] slice_reg2_q;
    reg [7:0] slice_reg3_q;

    // Wires for next state (combinational)
    wire [7:0] slice_reg0_next;
    wire [7:0] slice_reg1_next;
    wire [7:0] slice_reg2_next;
    wire [7:0] slice_reg3_next;

    // Intermediate wires for feedback calculation
    wire fb0_bit7_xor_bit5;
    wire fb0_bit4_xor_bit3;
    wire fb0_partial1;
    wire feedback0;

    wire fb1_bit7_xor_bit6;
    wire fb1_bit1_xor_bit0;
    wire fb1_partial1;
    wire feedback1;

    wire fb2_bit7_xor_bit6;
    wire fb2_bit5_xor_bit0;
    wire fb2_partial1;
    wire feedback2;

    wire fb3_bit7_xor_bit3;
    wire fb3_bit2_xor_bit1;
    wire fb3_partial1;
    wire feedback3;

    // Feedback calculation - slice_reg0
    assign fb0_bit7_xor_bit5 = slice_reg0_q[7] ^ slice_reg0_q[5];
    assign fb0_bit4_xor_bit3 = slice_reg0_q[4] ^ slice_reg0_q[3];
    assign fb0_partial1 = fb0_bit7_xor_bit5 ^ fb0_bit4_xor_bit3;
    assign feedback0 = fb0_partial1;

    // Feedback calculation - slice_reg1
    assign fb1_bit7_xor_bit6 = slice_reg1_q[7] ^ slice_reg1_q[6];
    assign fb1_bit1_xor_bit0 = slice_reg1_q[1] ^ slice_reg1_q[0];
    assign fb1_partial1 = fb1_bit7_xor_bit6 ^ fb1_bit1_xor_bit0;
    assign feedback1 = fb1_partial1;

    // Feedback calculation - slice_reg2
    assign fb2_bit7_xor_bit6 = slice_reg2_q[7] ^ slice_reg2_q[6];
    assign fb2_bit5_xor_bit0 = slice_reg2_q[5] ^ slice_reg2_q[0];
    assign fb2_partial1 = fb2_bit7_xor_bit6 ^ fb2_bit5_xor_bit0;
    assign feedback2 = fb2_partial1;

    // Feedback calculation - slice_reg3
    assign fb3_bit7_xor_bit3 = slice_reg3_q[7] ^ slice_reg3_q[3];
    assign fb3_bit2_xor_bit1 = slice_reg3_q[2] ^ slice_reg3_q[1];
    assign fb3_partial1 = fb3_bit7_xor_bit3 ^ fb3_bit2_xor_bit1;
    assign feedback3 = fb3_partial1;

    // Next-state calculation
    assign slice_reg0_next = {slice_reg0_q[6:0], feedback0};
    assign slice_reg1_next = {slice_reg1_q[6:0], feedback1};
    assign slice_reg2_next = {slice_reg2_q[6:0], feedback2};
    assign slice_reg3_next = {slice_reg3_q[6:0], feedback3};

    // Sequential logic for register update
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            slice_reg0_q <= 8'h1;
            slice_reg1_q <= 8'h2;
            slice_reg2_q <= 8'h4;
            slice_reg3_q <= 8'h8;
        end else begin
            slice_reg0_q <= slice_reg0_next;
            slice_reg1_q <= slice_reg1_next;
            slice_reg2_q <= slice_reg2_next;
            slice_reg3_q <= slice_reg3_next;
        end
    end

    // Output assignment
    assign rnd_o = {slice_reg3_q, slice_reg2_q, slice_reg1_q, slice_reg0_q};

endmodule