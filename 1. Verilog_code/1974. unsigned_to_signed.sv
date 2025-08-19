module unsigned_to_signed #(parameter WIDTH=16)(
    input wire [WIDTH-1:0] unsigned_in,
    output reg [WIDTH-1:0] signed_out,
    output reg overflow
);
    always @* begin
        overflow = unsigned_in[WIDTH-1];
        signed_out = unsigned_in[WIDTH-1] ? {1'b0, unsigned_in[WIDTH-2:0]} : unsigned_in;
    end
endmodule