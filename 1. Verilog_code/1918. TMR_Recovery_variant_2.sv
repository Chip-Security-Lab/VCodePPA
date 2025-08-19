//SystemVerilog
// Top-level module: TMR_Recovery
// Function: Triple Modular Redundancy (TMR) recovery logic with hierarchical structure

module TMR_Recovery #(parameter WIDTH=8) (
    input  [WIDTH-1:0] ch0,
    input  [WIDTH-1:0] ch1,
    input  [WIDTH-1:0] ch2,
    output [WIDTH-1:0] data_out
);

    wire [WIDTH-1:0] and_ch0_ch1;
    wire [WIDTH-1:0] and_ch1_ch2;
    wire [WIDTH-1:0] and_ch0_ch2;
    wire [WIDTH-1:0] maj_vote_result;

    // Instantiate TMR_AND_UNIT for ch0 and ch1
    TMR_AND_UNIT #(.WIDTH(WIDTH)) and_unit0 (
        .input_a(ch0),
        .input_b(ch1),
        .and_result(and_ch0_ch1)
    );

    // Instantiate TMR_AND_UNIT for ch1 and ch2
    TMR_AND_UNIT #(.WIDTH(WIDTH)) and_unit1 (
        .input_a(ch1),
        .input_b(ch2),
        .and_result(and_ch1_ch2)
    );

    // Instantiate TMR_AND_UNIT for ch0 and ch2
    TMR_AND_UNIT #(.WIDTH(WIDTH)) and_unit2 (
        .input_a(ch0),
        .input_b(ch2),
        .and_result(and_ch0_ch2)
    );

    // Instantiate TMR_MAJORITY_UNIT to combine AND results
    TMR_MAJORITY_UNIT #(.WIDTH(WIDTH)) majority_unit (
        .and_ab(and_ch0_ch1),
        .and_bc(and_ch1_ch2),
        .and_ac(and_ch0_ch2),
        .majority_result(maj_vote_result)
    );

    // Output buffer for timing improvement (optional)
    TMR_OUTPUT_BUFFER #(.WIDTH(WIDTH)) output_buffer (
        .in_data(maj_vote_result),
        .out_data(data_out)
    );

endmodule

// Submodule: TMR_AND_UNIT
// Function: Bitwise AND of two input vectors for TMR voting
module TMR_AND_UNIT #(parameter WIDTH=8) (
    input  [WIDTH-1:0] input_a,
    input  [WIDTH-1:0] input_b,
    output [WIDTH-1:0] and_result
);
    // Performs bitwise AND
    assign and_result = input_a & input_b;
endmodule

// Submodule: TMR_MAJORITY_UNIT
// Function: Bitwise OR of three input vectors representing AND results (majority voting)
module TMR_MAJORITY_UNIT #(parameter WIDTH=8) (
    input  [WIDTH-1:0] and_ab,
    input  [WIDTH-1:0] and_bc,
    input  [WIDTH-1:0] and_ac,
    output [WIDTH-1:0] majority_result
);
    // Performs bitwise OR to realize majority vote
    assign majority_result = and_ab | and_bc | and_ac;
endmodule

// Submodule: TMR_OUTPUT_BUFFER
// Function: Output register buffer to improve timing and PPA metrics
module TMR_OUTPUT_BUFFER #(parameter WIDTH=8) (
    input  [WIDTH-1:0] in_data,
    output [WIDTH-1:0] out_data
);
    // Registered output to improve timing closure and reduce glitches
    reg [WIDTH-1:0] data_reg;
    always @(*) begin
        data_reg = in_data;
    end
    assign out_data = data_reg;
endmodule