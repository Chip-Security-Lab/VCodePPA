//SystemVerilog
module fixed_point_saturator #(
    parameter IN_WIDTH = 16,
    parameter OUT_WIDTH = 8
)(
    input  wire signed [IN_WIDTH-1:0] in_data,
    output reg  signed [OUT_WIDTH-1:0] out_data,
    output reg  overflow
);

    // Stage 1: Extract relevant bit fields and calculate sign
    reg  [IN_WIDTH-OUT_WIDTH:0] upper_bits_stage1;
    reg  in_sign_stage1;
    reg  signed [OUT_WIDTH-1:0] in_data_trunc_stage1;

    always @* begin
        upper_bits_stage1      = in_data[IN_WIDTH-1:OUT_WIDTH-1];
        in_sign_stage1         = in_data[IN_WIDTH-1];
        in_data_trunc_stage1   = in_data[OUT_WIDTH-1:0];
    end

    // Stage 2: Check for overflow condition
    reg upper_bits_all_ones_stage2;
    reg upper_bits_all_zeros_stage2;
    reg upper_bits_same_stage2;
    reg overflow_stage2;

    always @* begin
        upper_bits_all_ones_stage2  = &upper_bits_stage1;
        upper_bits_all_zeros_stage2 = ~|upper_bits_stage1;
        upper_bits_same_stage2      = upper_bits_all_ones_stage2 | upper_bits_all_zeros_stage2;
        overflow_stage2             = ~upper_bits_same_stage2;
    end

    // Stage 3: Saturate or pass through data using conditional negate subtractor
    reg signed [OUT_WIDTH-1:0] max_val_stage3;
    reg signed [OUT_WIDTH-1:0] min_val_stage3;
    reg signed [OUT_WIDTH-1:0] out_data_stage3;

    // Conditional Negate Subtractor signals
    reg signed [OUT_WIDTH-1:0] a_subtrahend;
    reg signed [OUT_WIDTH-1:0] b_minuend;
    reg borrow_in;
    reg signed [OUT_WIDTH-1:0] b_inverted;
    reg signed [OUT_WIDTH-1:0] sum_stage3;
    reg carry_out_stage3;

    always @* begin
        max_val_stage3 = {1'b0, {(OUT_WIDTH-1){1'b1}}};
        min_val_stage3 = {1'b1, {(OUT_WIDTH-1){1'b0}}};

        // Default assignments
        out_data_stage3 = in_data_trunc_stage1;

        // Use conditional negate subtractor for saturation
        if (overflow_stage2) begin
            if (in_sign_stage1 == 1'b0) begin
                // Positive overflow: output maximum
                // out_data_stage3 = max_val_stage3;
                a_subtrahend = 0;
                b_minuend    = max_val_stage3;
                borrow_in    = 1'b0;
                b_inverted   = ~a_subtrahend;
                {carry_out_stage3, sum_stage3} = b_minuend + b_inverted + borrow_in;
                out_data_stage3 = sum_stage3;
            end else begin
                // Negative overflow: output minimum
                // out_data_stage3 = min_val_stage3;
                a_subtrahend = 0;
                b_minuend    = min_val_stage3;
                borrow_in    = 1'b0;
                b_inverted   = ~a_subtrahend;
                {carry_out_stage3, sum_stage3} = b_minuend + b_inverted + borrow_in;
                out_data_stage3 = sum_stage3;
            end
        end
    end

    // Stage 4: Register outputs for clarity and timing closure
    always @* begin
        out_data = out_data_stage3;
        overflow = overflow_stage2;
    end

endmodule