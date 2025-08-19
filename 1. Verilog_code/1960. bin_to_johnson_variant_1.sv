//SystemVerilog
module bin_to_johnson #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] bin_in,
    output reg [2*WIDTH-1:0] johnson_out
);
    wire [WIDTH:0] booth_modulus;
    reg  [WIDTH-1:0] modulus_operand;
    reg  [WIDTH-1:0] modulus_result;
    integer i;
    reg [WIDTH-1:0] pos;

    // Booth Multiplier instance
    booth_multiplier_8bit booth_modulus_inst (
        .multiplicand(bin_in),
        .multiplier(8'd1), // bin_in * 1
        .product(booth_modulus)
    );

    // Combined always block for combinational logic
    always @(*) begin
        modulus_operand = booth_modulus[WIDTH-1:0];
        modulus_result = modulus_operand;
        if (modulus_result >= 2*WIDTH)
            modulus_result = modulus_result - 2*WIDTH;
        pos = modulus_result;

        johnson_out = {2*WIDTH{1'b0}};
        for (i = 0; i < 2*WIDTH; i = i + 1) begin
            if (i < pos)
                johnson_out[i] = 1'b1;
            else
                johnson_out[i] = 1'b0;
        end
        if (pos > WIDTH) begin
            johnson_out = ~johnson_out;
        end
    end
endmodule

module booth_multiplier_8bit(
    input  [7:0] multiplicand,
    input  [7:0] multiplier,
    output reg [15:0] product
);
    reg [8:0] booth_multiplicand;
    reg [8:0] booth_product;
    reg [7:0] booth_multiplier;
    reg booth_bit;
    reg [15:0] booth_partial_product;
    integer i;

    // Combined always block for combinational logic
    always @(*) begin
        booth_multiplicand = {multiplicand[7], multiplicand};
        booth_multiplier = multiplier;
        booth_product = 9'd0;
        booth_partial_product = 16'd0;
        product = 16'd0;
        booth_bit = 1'b0;

        for (i = 0; i < 8; i = i + 1) begin
            case ({booth_multiplier[0], booth_bit})
                2'b01: booth_partial_product = booth_multiplicand << i;
                2'b10: booth_partial_product = (~booth_multiplicand + 1'b1) << i;
                default: booth_partial_product = 16'd0;
            endcase
            product = product + booth_partial_product;
            booth_bit = booth_multiplier[0];
            booth_multiplier = booth_multiplier >> 1;
        end
    end
endmodule