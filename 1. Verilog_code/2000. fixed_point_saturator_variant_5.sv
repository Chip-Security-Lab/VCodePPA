//SystemVerilog
module fixed_point_saturator #(parameter IN_WIDTH=16, OUT_WIDTH=8)(
    input wire signed [IN_WIDTH-1:0] in_data,
    output reg signed [OUT_WIDTH-1:0] out_data,
    output reg overflow
);
    // IEEE 1364-2005 compliant
    wire signed [OUT_WIDTH-1:0] max_value = {1'b0, {(OUT_WIDTH-1){1'b1}}};
    wire signed [OUT_WIDTH-1:0] min_value = {1'b1, {(OUT_WIDTH-1){1'b0}}};

    wire [IN_WIDTH-OUT_WIDTH:0] sign_extend_bits = in_data[IN_WIDTH-1:OUT_WIDTH-1];
    wire msb = in_data[IN_WIDTH-1];

    // upper_bits_same is 1 if all sign extension bits are equal to the sign bit
    wire upper_bits_same = ~(|(sign_extend_bits ^ { (IN_WIDTH-OUT_WIDTH+1){msb} }));

    always @* begin
        overflow = ~upper_bits_same;
        if (~msb & overflow) begin
            out_data = max_value;
        end else if (msb & overflow) begin
            out_data = min_value;
        end else begin
            out_data = in_data[OUT_WIDTH-1:0];
        end
    end
endmodule