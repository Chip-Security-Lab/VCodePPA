//SystemVerilog
module nibble_swap(
    input [15:0] data_in,
    input swap_en,
    output reg [15:0] data_out
);
    wire [15:0] swapped_data;
    wire [15:0] booth_multiplier_a;
    wire [15:0] booth_multiplier_b;
    wire [31:0] booth_product;

    // For demonstration, let's assume we want to multiply two nibbles after swapping.
    // We'll use the lowest two nibbles as inputs to the Booth multiplier when swap_en is high.
    // Otherwise, just pass data_in through.

    assign swapped_data = {data_in[3:0], data_in[7:4], data_in[11:8], data_in[15:12]};
    assign booth_multiplier_a = swap_en ? swapped_data[7:0] : 16'd0; // example: lower 8 bits (could be adjusted)
    assign booth_multiplier_b = swap_en ? swapped_data[15:8] : 16'd0; // upper 8 bits

    wire [15:0] booth_result;
    booth_multiplier_16bit booth_mult_u (
        .multiplicand(booth_multiplier_a),
        .multiplier(booth_multiplier_b),
        .product(booth_product)
    );

    assign booth_result = booth_product[15:0]; // Lower 16 bits as result

    always @(*) begin
        if (swap_en)
            data_out = booth_result;
        else
            data_out = data_in;
    end
endmodule

module booth_multiplier_16bit(
    input  [15:0] multiplicand,
    input  [15:0] multiplier,
    output reg [31:0] product
);
    reg [16:0] booth_multiplicand;
    reg [16:0] neg_booth_multiplicand;
    reg [33:0] booth_accumulator;
    reg [16:0] booth_multiplier;
    integer i;

    always @(*) begin
        booth_multiplicand = {multiplicand[15], multiplicand}; // sign-extended
        neg_booth_multiplicand = ~booth_multiplicand + 1'b1;
        booth_multiplier = {multiplier, 1'b0}; // append 0 for Booth's algorithm
        booth_accumulator = 34'd0;

        for (i = 0; i < 16; i = i + 1) begin
            case ({booth_multiplier[1:0]})
                2'b01: booth_accumulator[33:17] = booth_accumulator[33:17] + booth_multiplicand;
                2'b10: booth_accumulator[33:17] = booth_accumulator[33:17] + neg_booth_multiplicand;
                default: ;
            endcase
            // arithmetic right shift
            booth_accumulator = {booth_accumulator[33], booth_accumulator[33:1]};
            booth_multiplier = {booth_multiplier[16], booth_multiplier[16:1]};
        end
        product = booth_accumulator[32:1];
    end
endmodule