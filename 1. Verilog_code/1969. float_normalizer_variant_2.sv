//SystemVerilog
module float_normalizer #(
    parameter INT_WIDTH = 16,
    parameter EXP_WIDTH = 5,
    parameter FRAC_WIDTH = 10
)(
    input  wire [INT_WIDTH-1:0] int_in,
    output wire [EXP_WIDTH+FRAC_WIDTH-1:0] float_out,
    output reg  overflow
);

    //==================================================================
    // Stage 1: Leading One Detection
    //==================================================================
    reg [EXP_WIDTH-1:0] leading_one_position;
    reg                 leading_one_found;
    integer             idx;

    // Detect the position of the most significant '1' in int_in
    always @(*) begin : LEADING_ONE_DETECTION
        leading_one_position = {EXP_WIDTH{1'b0}};
        leading_one_found    = 1'b0;
        for (idx = INT_WIDTH-1; idx >= 0; idx = idx - 1) begin
            if (!leading_one_found && int_in[idx]) begin
                leading_one_position = idx[EXP_WIDTH-1:0];
                leading_one_found    = 1'b1;
            end
        end
    end

    //==================================================================
    // Stage 2: Pipeline Register for Leading One Results
    //==================================================================
    reg [EXP_WIDTH-1:0] leading_one_position_reg;
    reg                 leading_one_found_reg;

    // Latch leading one detection results
    always @(*) begin : LEADING_ONE_PIPELINE
        leading_one_position_reg = leading_one_position;
        leading_one_found_reg    = leading_one_found;
    end

    //==================================================================
    // Stage 3: Exponent Computation
    //==================================================================
    reg [EXP_WIDTH-1:0] exponent_value;

    // Compute exponent based on leading one position
    always @(*) begin : EXPONENT_COMPUTATION
        if (!leading_one_found_reg) begin
            exponent_value = {EXP_WIDTH{1'b0}};
        end else begin
            exponent_value = leading_one_position_reg;
        end
    end

    //==================================================================
    // Stage 4: Fraction Computation
    //==================================================================
    reg [FRAC_WIDTH-1:0] fraction_value;

    // Compute fraction based on leading one position
    always @(*) begin : FRACTION_COMPUTATION
        if (!leading_one_found_reg) begin
            fraction_value = {FRAC_WIDTH{1'b0}};
        end else if (leading_one_position_reg >= FRAC_WIDTH) begin
            if (leading_one_position_reg > 0)
                fraction_value = int_in[leading_one_position_reg-1 -: FRAC_WIDTH];
            else
                fraction_value = {FRAC_WIDTH{1'b0}};
        end else begin
            fraction_value = int_in << (FRAC_WIDTH - leading_one_position_reg);
        end
    end

    //==================================================================
    // Stage 5: Overflow Detection
    //==================================================================
    // Detect overflow if leading one position exceeds exponent range
    always @(*) begin : OVERFLOW_DETECTION
        if (leading_one_found_reg && leading_one_position_reg >= (1 << EXP_WIDTH))
            overflow = 1'b1;
        else
            overflow = 1'b0;
    end

    //==================================================================
    // Output Assignment
    //==================================================================
    assign float_out = {exponent_value, fraction_value};

endmodule