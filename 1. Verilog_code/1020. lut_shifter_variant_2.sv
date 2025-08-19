//SystemVerilog
// Top-level module for LUT-based shifter with hierarchical structure
module lut_shifter #(parameter W = 4) (
    input  wire [W-1:0] din,
    input  wire [1:0]   shift,
    output wire [W-1:0] dout
);

    // Internal wires for borrow subtractor results
    wire [1:0] shift_minus_1;
    wire [1:0] shift_minus_2;
    wire [1:0] shift_minus_3;

    // Instantiate 2-bit borrow subtractor submodules for shift-1, shift-2, shift-3
    borrow_subtractor_2bit sub_shift_minus_1 (
        .a    (shift),
        .b    (2'b01),
        .diff (shift_minus_1)
    );

    borrow_subtractor_2bit sub_shift_minus_2 (
        .a    (shift),
        .b    (2'b10),
        .diff (shift_minus_2)
    );

    borrow_subtractor_2bit sub_shift_minus_3 (
        .a    (shift),
        .b    (2'b11),
        .diff (shift_minus_3)
    );

    // Instantiate the shifting logic submodule
    shifter_core #(.W(W)) u_shifter_core (
        .din           (din),
        .shift         (shift),
        .dout          (dout)
    );

endmodule

// -----------------------------------------------------------------------------
// 2-bit Borrow Subtractor Module
// Performs a - b for 2-bit unsigned numbers, outputs 2-bit difference
// -----------------------------------------------------------------------------
module borrow_subtractor_2bit (
    input  wire [1:0] a,
    input  wire [1:0] b,
    output wire [1:0] diff
);
    // Internal signals for borrow and difference bits
    wire borrow0, diff0;
    wire borrow1, diff1;

    // LSB subtraction with borrow
    assign {borrow0, diff0} = {1'b0, a[0]} - {1'b0, b[0]};
    // MSB subtraction with borrow from previous
    assign {borrow1, diff1} = {1'b0, a[1]} - {1'b0, b[1]} - borrow0;

    assign diff = {diff1, diff0};
endmodule

// -----------------------------------------------------------------------------
// Shifter Core Module
// Performs left shift on input din according to shift amount
// -----------------------------------------------------------------------------
module shifter_core #(parameter W = 4) (
    input  wire [W-1:0] din,
    input  wire [1:0]   shift,
    output reg  [W-1:0] dout
);
    // Combinational shift logic
    always @(*) begin
        case (shift)
            2'b00: dout = din;
            2'b01: dout = {din[W-2:0], 1'b0};
            2'b10: dout = {din[W-3:0], 2'b00};
            2'b11: dout = {din[W-4:0], 3'b000};
            default: dout = {W{1'b0}};
        endcase
    end
endmodule