//SystemVerilog
module karatsuba_multiplier #(parameter WIDTH = 8) (
    input [WIDTH-1:0] multiplicand,
    input [WIDTH-1:0] multiplier,
    output reg [2*WIDTH-1:0] product
);

    wire [WIDTH/2-1:0] a_high = multiplicand[WIDTH-1:WIDTH/2];
    wire [WIDTH/2-1:0] a_low = multiplicand[WIDTH/2-1:0];
    wire [WIDTH/2-1:0] b_high = multiplier[WIDTH-1:WIDTH/2];
    wire [WIDTH/2-1:0] b_low = multiplier[WIDTH/2-1:0];

    wire [WIDTH-1:0] z0 = a_low * b_low;
    wire [WIDTH-1:0] z2 = a_high * b_high;
    wire [WIDTH-1:0] z1 = (a_high + a_low) * (b_high + b_low) - z2 - z0;

    always @* begin
        product = (z2 << WIDTH) + (z1 << (WIDTH/2)) + z0;
    end
endmodule

module decoder_async #(parameter ADDR_WIDTH = 3) (
    input [ADDR_WIDTH-1:0] addr,
    output reg [7:0] decoded
);

    wire [7:0] karatsuba_result;
    karatsuba_multiplier #(8) karatsuba_inst (
        .multiplicand(8'b00000001),
        .multiplier({5'b0, addr}),
        .product(karatsuba_result)
    );

    always @* begin
        decoded = karatsuba_result;
    end
endmodule