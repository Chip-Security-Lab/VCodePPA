//SystemVerilog
module float_normalizer #(
    parameter INT_WIDTH = 16,
    parameter EXP_WIDTH = 5,
    parameter FRAC_WIDTH = 10
)(
    input  [INT_WIDTH-1:0] int_in,
    output [EXP_WIDTH+FRAC_WIDTH-1:0] float_out,
    output reg overflow
);

    reg [EXP_WIDTH-1:0] exponent;
    reg [FRAC_WIDTH-1:0] fraction;
    reg [EXP_WIDTH-1:0] exponent_next;
    reg [FRAC_WIDTH-1:0] fraction_next;
    reg [EXP_WIDTH:0] leading_pos;
    integer idx;
    reg [EXP_WIDTH:0] leading_pos_next;

    // Find leading one position
    always @(*) begin : leading_one_detect
        leading_pos_next = {EXP_WIDTH+1{1'b0}} - 1;
        for (idx = INT_WIDTH - 1; idx >= 0; idx = idx - 1) begin
            if (int_in[idx] && (leading_pos_next == {EXP_WIDTH+1{1'b1}})) begin
                leading_pos_next = idx[EXP_WIDTH:0];
            end
        end
    end

    // Calculate exponent and fraction next
    always @(*) begin : exponent_fraction_compute
        if (leading_pos_next == {EXP_WIDTH+1{1'b1}}) begin // No '1' found
            exponent_next = {EXP_WIDTH{1'b0}};
            fraction_next = {FRAC_WIDTH{1'b0}};
        end else if (leading_pos_next >= FRAC_WIDTH) begin
            exponent_next = leading_pos_next[EXP_WIDTH-1:0];
            fraction_next = int_in[leading_pos_next-1 -: FRAC_WIDTH];
        end else begin
            exponent_next = leading_pos_next[EXP_WIDTH-1:0];
            fraction_next = int_in << (FRAC_WIDTH - leading_pos_next);
        end
    end

    // Register exponent and fraction for output
    always @(*) begin : output_register
        exponent = exponent_next;
        fraction = fraction_next;
    end

    // Overflow detection
    always @(*) begin : overflow_check
        if (leading_pos_next >= (1 << EXP_WIDTH))
            overflow = 1'b1;
        else
            overflow = 1'b0;
    end

    assign float_out = {exponent, fraction};

endmodule