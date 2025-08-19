module denormalizer #(parameter WIDTH=16)(
    input wire [WIDTH-1:0] in_data,
    input wire [$clog2(WIDTH)-1:0] shift_count,
    output reg [WIDTH-1:0] denormalized_data
);
    always @* begin
        denormalized_data = in_data >> shift_count;
    end
endmodule