//SystemVerilog
module signed_multiplier(
    input signed [15:0] multiplicand,
    input signed [15:0] multiplier,
    output reg signed [31:0] product
);

    reg signed [31:0] partial_sum;
    reg signed [15:0] abs_multiplicand;
    reg signed [15:0] abs_multiplier;
    reg sign_result;

    always @(*) begin
        abs_multiplicand = (multiplicand[15]) ? -multiplicand : multiplicand;
        abs_multiplier = (multiplier[15]) ? -multiplier : multiplier;
        sign_result = multiplicand[15] ^ multiplier[15];
        
        partial_sum = 32'd0;
        for (int i = 0; i < 16; i++) begin
            if (abs_multiplier[i]) begin
                partial_sum = partial_sum + (abs_multiplicand << i);
            end
        end
        
        product = sign_result ? -partial_sum : partial_sum;
    end

endmodule

module tristate_mux(
    input [15:0] input_bus_a, input_bus_b,
    input select, output_enable,
    output reg [15:0] muxed_bus
);

    wire [31:0] signed_product;
    signed_multiplier mult_inst(
        .multiplicand(input_bus_a),
        .multiplier(input_bus_b),
        .product(signed_product)
    );

    always @(*) begin
        if (output_enable) begin
            if (select) begin
                muxed_bus = signed_product[15:0];
            end else begin
                muxed_bus = input_bus_a;
            end
        end else begin
            muxed_bus = 16'bz;
        end
    end

endmodule