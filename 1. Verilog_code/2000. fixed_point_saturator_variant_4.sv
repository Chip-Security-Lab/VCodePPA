//SystemVerilog
module fixed_point_saturator #(parameter IN_WIDTH=16, OUT_WIDTH=8)(
    input wire signed [IN_WIDTH-1:0] in_data,
    output reg signed [OUT_WIDTH-1:0] out_data,
    output reg overflow
);

    // Maximum and minimum values representable by OUT_WIDTH
    wire signed [OUT_WIDTH-1:0] max_output_value;
    wire signed [OUT_WIDTH-1:0] min_output_value;
    assign max_output_value = {1'b0, {(OUT_WIDTH-1){1'b1}}};
    assign min_output_value = {1'b1, {(OUT_WIDTH-1){1'b0}}};

    // Extract sign bit
    wire input_sign_bit;
    assign input_sign_bit = in_data[IN_WIDTH-1];

    // Extract upper bits for overflow detection
    wire [IN_WIDTH-OUT_WIDTH:0] upper_data_bits;
    assign upper_data_bits = in_data[IN_WIDTH-1:OUT_WIDTH-1];

    // Generate sign extension pattern
    wire [IN_WIDTH-OUT_WIDTH:0] sign_extension_pattern;
    assign sign_extension_pattern = { (IN_WIDTH-OUT_WIDTH+1){input_sign_bit} };

    // Check if upper bits match sign extension
    wire upper_bits_equal_sign;
    assign upper_bits_equal_sign = (upper_data_bits == sign_extension_pattern);

    // Combined overflow status
    reg [1:0] overflow_type;

    always @* begin
        // overflow_type: 2'b00 - no overflow, 2'b01 - positive, 2'b10 - negative
        case ({upper_bits_equal_sign, input_sign_bit})
            2'b10: begin // upper_bits_equal_sign=1, input_sign_bit=0
                overflow_type = 2'b00; // no overflow
            end
            2'b11: begin // upper_bits_equal_sign=1, input_sign_bit=1
                overflow_type = 2'b00; // no overflow
            end
            2'b00: begin // upper_bits_equal_sign=0, input_sign_bit=0
                overflow_type = 2'b01; // positive overflow
            end
            2'b01: begin // upper_bits_equal_sign=0, input_sign_bit=1
                overflow_type = 2'b10; // negative overflow
            end
            default: overflow_type = 2'b00;
        endcase

        case (overflow_type)
            2'b01: begin // positive overflow
                out_data = max_output_value;
                overflow = 1'b1;
            end
            2'b10: begin // negative overflow
                out_data = min_output_value;
                overflow = 1'b1;
            end
            default: begin // no overflow
                out_data = in_data[OUT_WIDTH-1:0];
                overflow = 1'b0;
            end
        endcase
    end

endmodule