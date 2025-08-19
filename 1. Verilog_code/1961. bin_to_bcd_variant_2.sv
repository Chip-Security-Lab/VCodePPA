//SystemVerilog
// Top-level module: Hierarchical Binary to BCD Converter
module bin_to_bcd #(
    parameter BIN_WIDTH = 8,
    parameter DIGITS = 3  // Number of output BCD digits
)(
    input  [BIN_WIDTH-1:0] binary_in,
    output [DIGITS*4-1:0]  bcd_out
);

    // Internal signal for the shift register
    wire [BIN_WIDTH+DIGITS*4-1:0] shift_reg_final;

    // Instantiate the shift/adjust core module
    bin_to_bcd_core #(
        .BIN_WIDTH(BIN_WIDTH),
        .DIGITS(DIGITS)
    ) u_bin_to_bcd_core (
        .binary_in(binary_in),
        .shift_reg_out(shift_reg_final)
    );

    // Assign the BCD output from the final shift register
    assign bcd_out = shift_reg_final[BIN_WIDTH+DIGITS*4-1:BIN_WIDTH];

endmodule

// Submodule: bin_to_bcd_core
// Performs Double Dabble (shift and adjust) algorithm
module bin_to_bcd_core #(
    parameter BIN_WIDTH = 8,
    parameter DIGITS = 3
)(
    input  [BIN_WIDTH-1:0] binary_in,
    output [BIN_WIDTH+DIGITS*4-1:0] shift_reg_out
);
    integer k;
    reg [BIN_WIDTH+DIGITS*4-1:0] adjusted_temp [0:BIN_WIDTH];
    reg [DIGITS*4-1:0] bcd_digits_in;
    reg [DIGITS*4-1:0] bcd_digits_out;
    reg [BIN_WIDTH+DIGITS*4-1:0] pre_shift;

    // Temporary wires for combinational assignment
    wire [BIN_WIDTH+DIGITS*4-1:0] adjusted_temp_wire [0:BIN_WIDTH];

    assign adjusted_temp_wire[0] = {{(DIGITS*4){1'b0}}, binary_in};

    // Unroll the while loop for combinational logic
    // This replaces the original for-generate with a while-generate style

    genvar idx;
    generate
        for (idx = 0; idx < BIN_WIDTH; idx = idx + 1) begin : SHIFT_STAGE
            wire [DIGITS*4-1:0] bcd_digits_in_wire;
            assign bcd_digits_in_wire = adjusted_temp_wire[idx][BIN_WIDTH+DIGITS*4-1:BIN_WIDTH];
            wire [DIGITS*4-1:0] bcd_digits_out_wire;

            // Instantiate the adjuster for this stage
            bcd_adjuster #(
                .DIGITS(DIGITS)
            ) u_bcd_adjuster (
                .bcd_in(bcd_digits_in_wire),
                .bcd_out(bcd_digits_out_wire)
            );

            // Concatenate adjusted BCD with binary
            wire [BIN_WIDTH+DIGITS*4-1:0] pre_shift_wire;
            assign pre_shift_wire = {bcd_digits_out_wire, adjusted_temp_wire[idx][BIN_WIDTH-1:0]};

            // Shift left by 1
            assign adjusted_temp_wire[idx+1] = pre_shift_wire << 1;
        end
    endgenerate

    assign shift_reg_out = adjusted_temp_wire[BIN_WIDTH];

endmodule

// Submodule: bcd_adjuster
// Adds 3 to any BCD digit > 4 as required by the Double Dabble algorithm
module bcd_adjuster #(
    parameter DIGITS = 3
)(
    input  [DIGITS*4-1:0] bcd_in,
    output [DIGITS*4-1:0] bcd_out
);
    integer j;
    reg [3:0] digit_in;
    reg [3:0] digit_out;
    reg [DIGITS*4-1:0] bcd_out_reg;

    always @(*) begin
        j = 0;
        while (j < DIGITS) begin
            digit_in = bcd_in[j*4 +: 4];
            if (digit_in > 4'd4)
                digit_out = digit_in + 4'd3;
            else
                digit_out = digit_in;
            bcd_out_reg[j*4 +: 4] = digit_out;
            j = j + 1;
        end
    end

    assign bcd_out = bcd_out_reg;

endmodule