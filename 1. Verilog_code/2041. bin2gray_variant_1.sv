//SystemVerilog
// Top-level module: Hierarchical binary to Gray code converter (modularized)

module bin2gray_top #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] bin_in,
    output wire [WIDTH-1:0] gray_out
);

    // Internal signals
    wire [WIDTH-1:0] shifted_bin;
    wire [WIDTH-1:0] xor_result;

    // Instantiate right shift logic
    bin2gray_right_shifter #(.WIDTH(WIDTH)) u_right_shifter (
        .data_in(bin_in),
        .data_out(shifted_bin)
    );

    // Instantiate Gray XOR logic
    bin2gray_xor_unit #(.WIDTH(WIDTH)) u_xor_unit (
        .a(bin_in),
        .b(shifted_bin),
        .y(xor_result)
    );

    // Output register for Gray code (optional: improves timing/PPA)
    bin2gray_outreg #(.WIDTH(WIDTH)) u_gray_outreg (
        .d(xor_result),
        .q(gray_out)
    );

endmodule

// -----------------------------------------------------------------------------
// bin2gray_right_shifter
// Shifts input vector right by 1, fills MSB with 0
// -----------------------------------------------------------------------------
module bin2gray_right_shifter #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : shift_right
            assign data_out[i] = (i == WIDTH-1) ? 1'b0 : data_in[i+1];
        end
    endgenerate
endmodule

// -----------------------------------------------------------------------------
// bin2gray_xor_unit
// Performs bitwise XOR between two inputs
// -----------------------------------------------------------------------------
module bin2gray_xor_unit #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    assign y = a ^ b;
endmodule

// -----------------------------------------------------------------------------
// bin2gray_outreg
// Output register for Gray code (for improved timing/area/power)
// -----------------------------------------------------------------------------
module bin2gray_outreg #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] d,
    output wire [WIDTH-1:0] q
);
    // Asynchronous combinational output (register can be replaced with sequential if needed)
    assign q = d;
endmodule