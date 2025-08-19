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
    reg [31:0] leading_one_position;
    integer i;

    // Leading one detector
    always @(*) begin : leading_one_detection
        leading_one_position = {32{1'b0}};
        for (i = INT_WIDTH-1; i >= 0; i = i - 1) begin
            if (int_in[i] && (leading_one_position == 0))
                leading_one_position = i;
        end
        if (leading_one_position == 0 && int_in[0] == 0)
            leading_one_position = {32{1'b1}}; // -1 for 2's complement
    end

    // Exponent, Fraction, and Overflow calculation using case
    always @(*) begin : normalization_logic
        case (leading_one_position)
            {32{1'b1}}: begin // No leading one found
                exponent = {EXP_WIDTH{1'b0}};
                fraction = {FRAC_WIDTH{1'b0}};
                overflow = 1'b0;
            end
            default: begin
                if (leading_one_position >= (1 << EXP_WIDTH)) begin
                    exponent = leading_one_position[EXP_WIDTH-1:0];
                    if (leading_one_position >= FRAC_WIDTH)
                        fraction = int_in[leading_one_position-1 -: FRAC_WIDTH];
                    else
                        fraction = int_in << (FRAC_WIDTH - leading_one_position);
                    overflow = 1'b1;
                end else begin
                    exponent = leading_one_position[EXP_WIDTH-1:0];
                    if (leading_one_position >= FRAC_WIDTH)
                        fraction = int_in[leading_one_position-1 -: FRAC_WIDTH];
                    else
                        fraction = int_in << (FRAC_WIDTH - leading_one_position);
                    overflow = 1'b0;
                end
            end
        endcase
    end

    assign float_out = {exponent, fraction};

endmodule