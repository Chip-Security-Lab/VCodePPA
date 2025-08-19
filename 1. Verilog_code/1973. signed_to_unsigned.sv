module signed_to_unsigned #(parameter WIDTH=16)(
    input wire [WIDTH-1:0] signed_in,
    output reg [WIDTH-1:0] unsigned_out,
    output reg overflow
);
    always @* begin
        overflow = signed_in[WIDTH-1];
        unsigned_out = signed_in[WIDTH-1] ? {WIDTH{1'b0}} : signed_in;
    end
endmodule