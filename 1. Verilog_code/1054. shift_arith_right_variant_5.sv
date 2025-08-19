//SystemVerilog
// Top-level module: shift_arith_right
module shift_arith_right #(parameter WIDTH=8) (
    input  [WIDTH-1:0] data_in,
    input  [2:0] shift_amount,
    output [WIDTH-1:0] data_out
);

    // Internal signals
    wire [2:0] shift_amt_borrow;
    wire signed [WIDTH-1:0] signed_data_in;
    wire signed [WIDTH-1:0] shifted_data;

    // Subtractor submodule: 3-bit borrow subtractor
    subtractor_3bit_borrow u_subtractor_3bit_borrow (
        .minuend   (shift_amount),
        .subtrahend(3'b000),
        .diff      (shift_amt_borrow)
    );

    // Sign extension submodule: Converts unsigned input to signed
    sign_extender #(WIDTH) u_sign_extender (
        .unsigned_in (data_in),
        .signed_out  (signed_data_in)
    );

    // Arithmetic right shifter submodule
    arith_right_shifter #(WIDTH) u_arith_right_shifter (
        .data_in        (signed_data_in),
        .shift_amount   (shift_amt_borrow),
        .shifted_result (shifted_data)
    );

    // Output assign
    assign data_out = shifted_data;

endmodule

// -----------------------------------------------------------------------------
// Submodule: subtractor_3bit_borrow
// 3-bit borrow subtractor, computes diff = minuend - subtrahend
// -----------------------------------------------------------------------------
module subtractor_3bit_borrow (
    input  [2:0] minuend,
    input  [2:0] subtrahend,
    output [2:0] diff
);
    reg [2:0] diff_reg;
    reg [2:0] borrow;
    integer i;
    always @* begin
        borrow = 3'b000;
        for (i = 0; i < 3; i = i + 1) begin
            diff_reg[i] = minuend[i] ^ subtrahend[i] ^ borrow[i];
            if (i < 2)
                borrow[i+1] = (~minuend[i] & subtrahend[i]) | ((~minuend[i] | subtrahend[i]) & borrow[i]);
        end
    end
    assign diff = diff_reg;
endmodule

// -----------------------------------------------------------------------------
// Submodule: sign_extender
// Converts unsigned input to signed output for arithmetic operations
// -----------------------------------------------------------------------------
module sign_extender #(parameter WIDTH=8) (
    input  [WIDTH-1:0] unsigned_in,
    output signed [WIDTH-1:0] signed_out
);
    assign signed_out = $signed(unsigned_in);
endmodule

// -----------------------------------------------------------------------------
// Submodule: arith_right_shifter
// Performs arithmetic right shift on signed data
// -----------------------------------------------------------------------------
module arith_right_shifter #(parameter WIDTH=8) (
    input  signed [WIDTH-1:0] data_in,
    input  [2:0] shift_amount,
    output signed [WIDTH-1:0] shifted_result
);
    assign shifted_result = data_in >>> shift_amount;
endmodule