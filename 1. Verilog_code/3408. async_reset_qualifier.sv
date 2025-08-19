module async_reset_qualifier(
    input wire raw_reset,
    input wire [3:0] qualifiers,
    output wire [3:0] qualified_resets
);
    assign qualified_resets[0] = raw_reset & qualifiers[0];
    assign qualified_resets[1] = raw_reset & qualifiers[1];
    assign qualified_resets[2] = raw_reset & qualifiers[2];
    assign qualified_resets[3] = raw_reset & qualifiers[3];
endmodule