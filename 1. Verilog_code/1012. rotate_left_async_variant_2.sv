//SystemVerilog
module rotate_left_async #(parameter WIDTH=8) (
    input  [WIDTH-1:0] din,
    input  [$clog2(WIDTH)-1:0] shift,
    output [WIDTH-1:0] dout
);
    wire [$clog2(WIDTH)-1:0] shift_borrow_sub_result;

    // Borrow subtractor for (WIDTH - shift)
    borrow_subtractor #(
        .WIDTH($clog2(WIDTH))
    ) u_borrow_subtractor (
        .minuend({{($clog2(WIDTH)){1'b0}}} + WIDTH), // WIDTH as a constant vector
        .subtrahend(shift),
        .difference(shift_borrow_sub_result)
    );

    assign dout = (din << shift) | (din >> shift_borrow_sub_result);

endmodule

module borrow_subtractor #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] minuend,
    input  [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] difference
);
    wire [WIDTH-1:0] borrow;
    wire [WIDTH-1:0] diff_internal;

    assign borrow[0] = (minuend[0] < subtrahend[0]);
    assign diff_internal[0] = minuend[0] ^ subtrahend[0];

    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_borrow_subtract
            assign borrow[i] = ((minuend[i] ^ borrow[i-1]) < subtrahend[i]);
            assign diff_internal[i] = minuend[i] ^ subtrahend[i] ^ borrow[i-1];
        end
    endgenerate

    assign difference = diff_internal;

endmodule