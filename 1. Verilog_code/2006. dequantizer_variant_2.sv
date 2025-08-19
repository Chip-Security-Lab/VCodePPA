//SystemVerilog
module dequantizer #(parameter B=8)(
    input  wire [15:0] qval,
    input  wire [15:0] scale,
    output reg  [15:0] deq
);

    reg [31:0] product;
    reg [15:0] abs_qval;
    reg [15:0] abs_scale;
    reg        result_sign;
    reg        qval_neg;
    reg        scale_neg;
    reg        product_neg;
    reg [15:0] sat_pos_limit;
    reg [15:0] sat_neg_limit;
    reg        sat_pos;
    reg        sat_neg;
    integer    i;

    always @* begin
        // Determine sign bits
        qval_neg  = qval[15];
        scale_neg = scale[15];

        // Absolute values
        abs_qval  = qval_neg  ? (~qval  + 16'd1) : qval;
        abs_scale = scale_neg ? (~scale + 16'd1) : scale;

        // Perform shift-add multiplication
        product = 32'd0;
        for (i = 0; i < 16; i = i + 1) begin
            if (abs_qval[i])
                product = product + (abs_scale << i);
        end

        // Determine result sign
        result_sign = qval_neg ^ scale_neg;

        // Apply sign to product
        if (result_sign)
            product = ~product + 32'd1;

        // Compute saturation limits
        sat_pos_limit = 16'd32767;
        sat_neg_limit = 16'h8000; // -32768

        // Determine product sign after sign application
        product_neg = product[31];

        // Check for saturation
        sat_pos = (product_neg == 1'b0) && (product[15:0] > sat_pos_limit);
        sat_neg = (product_neg == 1'b1) && (product[15:0] > sat_neg_limit);

        // Decision tree for output
        if (sat_pos)
            deq = sat_pos_limit;
        else if (sat_neg)
            deq = sat_neg_limit;
        else
            deq = product[15:0];
    end

endmodule