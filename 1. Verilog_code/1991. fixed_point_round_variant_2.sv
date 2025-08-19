//SystemVerilog
// Top-level module: Hierarchical fixed-point rounding with overflow detection
module fixed_point_round #(
    parameter IN_WIDTH = 16,
    parameter OUT_WIDTH = 8
)(
    input  wire [IN_WIDTH-1:0] in_data,
    output wire [OUT_WIDTH-1:0] out_data,
    output wire                 overflow
);

    wire [OUT_WIDTH-1:0] rounded_data;
    wire                 round_overflow;

    // Rounding Core: Handles rounding and overflow detection when OUT_WIDTH < IN_WIDTH
    fixed_point_round_core #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) u_core (
        .in_data      (in_data),
        .rounded_data (rounded_data),
        .overflow     (round_overflow)
    );

    // Output Selector: Selects between extended or rounded data based on width relationship
    fixed_point_round_output_sel #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) u_output_sel (
        .in_data      (in_data),
        .rounded_data (rounded_data),
        .overflow_in  (round_overflow),
        .out_data     (out_data),
        .overflow     (overflow)
    );

endmodule

// Submodule: Core Rounding and Overflow Detection
// Performs rounding and overflow detection when output is narrower than input
module fixed_point_round_core #(
    parameter IN_WIDTH = 16,
    parameter OUT_WIDTH = 8
)(
    input  wire [IN_WIDTH-1:0] in_data,
    output wire [OUT_WIDTH-1:0] rounded_data,
    output wire                 overflow
);
    generate
        if (OUT_WIDTH < IN_WIDTH) begin : gen_round
            wire round_bit;
            assign round_bit = in_data[IN_WIDTH-OUT_WIDTH-1];
            wire [OUT_WIDTH:0] add_operand;
            wire [OUT_WIDTH:0] sub_operand;
            wire [OUT_WIDTH:0] sub_operand_inverted;
            wire [OUT_WIDTH:0] sum_result;
            wire carry_in;
            wire [OUT_WIDTH:0] conditionally_inverted_b;

            // Operand A: {1'b0, in_data[IN_WIDTH-1:IN_WIDTH-OUT_WIDTH]}
            assign add_operand = {1'b0, in_data[IN_WIDTH-1:IN_WIDTH-OUT_WIDTH]};
            // Operand B: round_bit
            assign sub_operand = { {OUT_WIDTH{1'b0}}, round_bit };

            // Conditional inversion for subtraction using conditional negation algorithm
            assign sub_operand_inverted = sub_operand ^ {OUT_WIDTH+1{round_bit}};
            assign carry_in = round_bit;

            // Conditional adder/subtractor: add_operand + (sub_operand ^ {OUT_WIDTH+1{round_bit}}) + round_bit
            assign sum_result = add_operand + sub_operand_inverted + carry_in;

            assign rounded_data = sum_result[OUT_WIDTH-1:0];
            assign overflow     = sum_result[OUT_WIDTH] != sum_result[OUT_WIDTH-1];
        end else begin : gen_no_round
            assign rounded_data = {OUT_WIDTH{1'b0}};
            assign overflow     = 1'b0;
        end
    endgenerate
endmodule

// Submodule: Output Selector and Data Extension
// Selects correct output and overflow based on input/output width relationship
module fixed_point_round_output_sel #(
    parameter IN_WIDTH = 16,
    parameter OUT_WIDTH = 8
)(
    input  wire [IN_WIDTH-1:0]  in_data,
    input  wire [OUT_WIDTH-1:0] rounded_data,
    input  wire                 overflow_in,
    output reg  [OUT_WIDTH-1:0] out_data,
    output reg                  overflow
);
    always @* begin
        if (OUT_WIDTH >= IN_WIDTH) begin
            // Output is wider or equal: Sign-extend input, no overflow
            out_data  = {{(OUT_WIDTH-IN_WIDTH){in_data[IN_WIDTH-1]}}, in_data};
            overflow  = 1'b0;
        end else begin
            // Output is narrower: Use rounded value and overflow from core
            out_data  = rounded_data;
            overflow  = overflow_in;
        end
    end
endmodule