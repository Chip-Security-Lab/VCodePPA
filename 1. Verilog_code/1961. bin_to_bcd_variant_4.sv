//SystemVerilog
// Top-level module: Hierarchical binary to BCD converter with barrel shifter
module bin_to_bcd #(
    parameter BIN_WIDTH = 8,
    parameter DIGITS = 3  // Number of BCD digits in output
)(
    input  [BIN_WIDTH-1:0] binary_in,
    output [DIGITS*4-1:0]  bcd_out
);
    // Internal signal for the shift/add-3 algorithm
    wire [BIN_WIDTH+DIGITS*4-1:0] bcd_shift_result;

    // BCD conversion core: executes the double-dabble algorithm with barrel shifter
    bcd_shift_add3_core #(
        .BIN_WIDTH(BIN_WIDTH),
        .DIGITS(DIGITS)
    ) u_bcd_shift_add3_core (
        .binary_in(binary_in),
        .bcd_full_out(bcd_shift_result)
    );

    // Extracts the BCD output from the shift register result
    bcd_output_extract #(
        .BIN_WIDTH(BIN_WIDTH),
        .DIGITS(DIGITS)
    ) u_bcd_output_extract (
        .bcd_shift_reg(bcd_shift_result),
        .bcd_out(bcd_out)
    );

endmodule

// -------------------------------------------------------------------
// Submodule: bcd_shift_add3_core
// Implements the double-dabble (shift/add-3) algorithm using barrel shifter
// -------------------------------------------------------------------
module bcd_shift_add3_core #(
    parameter BIN_WIDTH = 8,
    parameter DIGITS = 3
)(
    input  [BIN_WIDTH-1:0] binary_in,
    output reg [BIN_WIDTH+DIGITS*4-1:0] bcd_full_out
);
    integer i, j;
    reg [BIN_WIDTH+DIGITS*4-1:0] temp;
    wire [BIN_WIDTH+DIGITS*4-1:0] barrel_shifted [0:BIN_WIDTH];

    // Initial assignment
    assign barrel_shifted[0] = { {DIGITS*4{1'b0}}, binary_in };

    // Generate barrel shifter stages
    genvar k;
    generate
        for (k = 0; k < BIN_WIDTH; k = k + 1) begin : barrel_stage
            wire [BIN_WIDTH+DIGITS*4-1:0] bcd_adjusted;
            integer m;
            reg [BIN_WIDTH+DIGITS*4-1:0] temp_stage;
            always @(*) begin
                temp_stage = barrel_shifted[k];
                for (m = 0; m < DIGITS; m = m + 1) begin
                    if (temp_stage[BIN_WIDTH+m*4 +: 4] > 4'd4)
                        temp_stage[BIN_WIDTH+m*4 +: 4] = temp_stage[BIN_WIDTH+m*4 +: 4] + 4'd3;
                end
            end
            // Barrel shifter: shift left by 1 using muxes
            assign barrel_shifted[k+1] = {temp_stage[BIN_WIDTH+DIGITS*4-2:0], 1'b0};
        end
    endgenerate

    always @(*) begin
        bcd_full_out = barrel_shifted[BIN_WIDTH];
    end
endmodule

// -------------------------------------------------------------------
// Submodule: bcd_output_extract
// Extracts the BCD output from the full shift register
// -------------------------------------------------------------------
module bcd_output_extract #(
    parameter BIN_WIDTH = 8,
    parameter DIGITS = 3
)(
    input  [BIN_WIDTH+DIGITS*4-1:0] bcd_shift_reg,
    output [DIGITS*4-1:0]           bcd_out
);
    // Assign only the BCD digits portion of the shift register to output
    assign bcd_out = bcd_shift_reg[BIN_WIDTH+DIGITS*4-1:BIN_WIDTH];
endmodule