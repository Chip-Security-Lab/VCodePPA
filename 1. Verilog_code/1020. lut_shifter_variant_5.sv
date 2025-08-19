//SystemVerilog
// Top-level hierarchical design for LUT-based shifter

module lut_shifter #(
    parameter W=4
)(
    input  [W-1:0] din,
    input  [1:0]   shift,
    output [W-1:0] dout
);

    // Internal wires for borrow subtractor results
    wire [1:0] shift_minus_1;
    wire [1:0] shift_minus_2;
    wire [1:0] shift_minus_3;
    wire       shift_borrow1, shift_borrow2, shift_borrow3;

    // Submodule: 2-bit borrow subtractor for (shift - 1)
    borrow_subtractor_2bit u_sub1 (
        .minuend    (shift),
        .subtrahend (2'b01),
        .diff       (shift_minus_1),
        .borrow_out (shift_borrow1)
    );

    // Submodule: 2-bit borrow subtractor for (shift - 2)
    borrow_subtractor_2bit u_sub2 (
        .minuend    (shift),
        .subtrahend (2'b10),
        .diff       (shift_minus_2),
        .borrow_out (shift_borrow2)
    );

    // Submodule: 2-bit borrow subtractor for (shift - 3)
    borrow_subtractor_2bit u_sub3 (
        .minuend    (shift),
        .subtrahend (2'b11),
        .diff       (shift_minus_3),
        .borrow_out (shift_borrow3)
    );

    // Submodule: Shift logic unit
    lut_shift_logic #(.W(W)) u_shift_logic (
        .din        (din),
        .shift      (shift),
        .dout       (dout)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: 2-bit borrow subtractor
// Performs (minuend - subtrahend) with borrow
// -----------------------------------------------------------------------------
module borrow_subtractor_2bit (
    input  [1:0] minuend,
    input  [1:0] subtrahend,
    output [1:0] diff,
    output       borrow_out
);
    wire b0, b1;
    wire d0, d1;

    assign d0 = minuend[0] ^ subtrahend[0];
    assign b0 = (~minuend[0]) & subtrahend[0];

    assign d1 = minuend[1] ^ subtrahend[1] ^ b0;
    assign b1 = ((~minuend[1]) & subtrahend[1]) | ((~minuend[1]) & b0) | (subtrahend[1] & b0);

    assign diff = {d1, d0};
    assign borrow_out = b1;
endmodule

// -----------------------------------------------------------------------------
// Submodule: LUT-based shifter logic
// Shifts input 'din' left by the amount specified in 'shift'
// -----------------------------------------------------------------------------
module lut_shift_logic #(
    parameter W=4
)(
    input  [W-1:0] din,
    input  [1:0]   shift,
    output reg [W-1:0] dout
);
    always @(*) begin
        case(shift)
            2'b00: dout = din;
            2'b01: dout = {din[W-2:0], 1'b0};
            2'b10: dout = {din[W-3:0], 2'b00};
            2'b11: dout = {din[W-4:0], 3'b000};
            default: dout = {W{1'b0}};
        endcase
    end
endmodule