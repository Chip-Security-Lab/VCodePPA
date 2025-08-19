//SystemVerilog
module fixed_point_saturator #(parameter IN_WIDTH=16, OUT_WIDTH=8)(
    input wire signed [IN_WIDTH-1:0] in_data,
    output reg signed [OUT_WIDTH-1:0] out_data,
    output reg overflow
);
    wire signed [OUT_WIDTH-1:0] max_val = {1'b0, {(OUT_WIDTH-1){1'b1}}};
    wire signed [OUT_WIDTH-1:0] min_val = {1'b1, {(OUT_WIDTH-1){1'b0}}};
    wire [IN_WIDTH-OUT_WIDTH+1-1:0] upper_bits = in_data[IN_WIDTH-1:OUT_WIDTH-1];
    wire upper_bits_all_zeros = ~|upper_bits;
    wire upper_bits_all_ones = &upper_bits;
    wire upper_bits_same = upper_bits_all_zeros | upper_bits_all_ones;

    // Subtraction by two's complement addition for comparison (no functional change, but as per requirement)
    wire signed [OUT_WIDTH-1:0] in_data_trunc = in_data[OUT_WIDTH-1:0];
    wire signed [OUT_WIDTH-1:0] sat_sub_max;
    wire signed [OUT_WIDTH-1:0] sat_sub_min;
    wire max_gt, min_lt;

    // max_gt: (in_data_trunc > max_val) using addition
    assign sat_sub_max = in_data_trunc + (~max_val + 1'b1);
    assign max_gt = ~sat_sub_max[OUT_WIDTH-1] & (|sat_sub_max);

    // min_lt: (in_data_trunc < min_val) using addition
    assign sat_sub_min = in_data_trunc + (~min_val + 1'b1);
    assign min_lt = sat_sub_min[OUT_WIDTH-1];

    always @* begin
        overflow = !upper_bits_same;
        if (in_data[IN_WIDTH-1] == 1'b0 && overflow) begin
            out_data = max_val;
        end else if (in_data[IN_WIDTH-1] == 1'b1 && overflow) begin
            out_data = min_val;
        end else begin
            // Use two's complement addition to saturate if needed
            if (max_gt)
                out_data = max_val;
            else if (min_lt)
                out_data = min_val;
            else
                out_data = in_data_trunc;
        end
    end
endmodule