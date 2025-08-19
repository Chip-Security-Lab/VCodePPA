//SystemVerilog
module fixed_point #(parameter Q=4, DW=8) (
    input  signed [DW-1:0] in,
    output signed [DW-1:0] out
);
    wire signed [DW-1:0] shifted_in;
    wire signed [DW-1:0] abs_shifted_in;

    // Efficient arithmetic right shift
    assign shifted_in = in >>> Q;

    // Use conditional negation based on input sign for optimized hardware implementation
    assign abs_shifted_in = (in[DW-1]) ? -shifted_in : shifted_in;

    assign out = abs_shifted_in;

endmodule