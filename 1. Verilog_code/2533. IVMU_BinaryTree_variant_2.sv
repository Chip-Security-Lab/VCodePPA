//SystemVerilog
module LUT_Subtractor_4bit (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output borrow
);

// This block describes the combinational logic for a 4-bit unsigned subtractor with borrow.
// Synthesis tools are expected to map this logic to lookup tables (LUTs).
reg [4:0] lut_output_reg; // {borrow, diff}

always @(*) begin
    integer a_int, b_int, result_int;

    // Convert unsigned inputs to integer for arithmetic calculation
    a_int = a;
    b_int = b;

    // Perform subtraction
    result_int = a_int - b_int;

    // Determine borrow and difference based on the result using conditional operator
    // If result_int < 0, borrow is 1, diff is result_int[3:0] (2's complement of unsigned diff)
    // If result_int >= 0, borrow is 0, diff is result_int[3:0] (unsigned diff)
    lut_output_reg = (result_int < 0) ? {1'b1, result_int[3:0]} : {1'b0, result_int[3:0]};
end

// Assign the calculated results to the output wires
assign borrow = lut_output_reg[4];
assign diff = lut_output_reg[3:0];

endmodule