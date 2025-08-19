module signed2unsigned_unit #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0]   signed_in,
    output wire [WIDTH-1:0]   unsigned_out,
    output wire               overflow
);
    // Convert signed to unsigned by adding offset
    assign unsigned_out = signed_in + {1'b1, {(WIDTH-1){1'b0}}};
    // Detect overflow
    assign overflow = signed_in[WIDTH-1];
endmodule