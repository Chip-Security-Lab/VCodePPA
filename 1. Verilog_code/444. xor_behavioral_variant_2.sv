//SystemVerilog IEEE 1364-2005
module xor_behavioral(
    input wire clk,       // Clock input
    input wire rst_n,     // Reset input, active low
    input wire a,         // Input operand A
    input wire b,         // Input operand B
    output wire y_out     // Output result
);
    // Internal connections between pipeline stages
    wire a_reg, b_reg;
    wire a_neg, b_neg;
    wire term1, term2;
    wire y_result;

    // Instantiate Stage 1: Input Registration
    input_register stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .a_in(a),
        .b_in(b),
        .a_out(a_reg),
        .b_out(b_reg)
    );

    // Instantiate Stage 2: Signal Negation
    signal_negation stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .a_in(a_reg),
        .b_in(b_reg),
        .a_neg_out(a_neg),
        .b_neg_out(b_neg)
    );

    // Instantiate Stage 3: Term Calculation
    term_calculator stage3 (
        .clk(clk),
        .rst_n(rst_n),
        .a_in(a_reg),
        .b_in(b_reg),
        .a_neg_in(a_neg),
        .b_neg_in(b_neg),
        .term1_out(term1),
        .term2_out(term2)
    );

    // Instantiate Stage 4: Result Combination
    result_combiner stage4 (
        .clk(clk),
        .rst_n(rst_n),
        .term1_in(term1),
        .term2_in(term2),
        .result_out(y_result)
    );

    // Instantiate Final Stage: Output Registration
    output_register stage5 (
        .clk(clk),
        .rst_n(rst_n),
        .result_in(y_result),
        .y_out(y_out)
    );

endmodule

// Stage 1: Input registration module
module input_register (
    input wire clk,
    input wire rst_n,
    input wire a_in,
    input wire b_in,
    output reg a_out,
    output reg b_out
);
    // Register inputs to break timing path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out <= 1'b0;
            b_out <= 1'b0;
        end else begin
            a_out <= a_in;
            b_out <= b_in;
        end
    end
endmodule

// Stage 2: Signal negation module
module signal_negation (
    input wire clk,
    input wire rst_n,
    input wire a_in,
    input wire b_in,
    output reg a_neg_out,
    output reg b_neg_out
);
    // Generate negated signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_neg_out <= 1'b0;
            b_neg_out <= 1'b0;
        end else begin
            a_neg_out <= ~a_in;
            b_neg_out <= ~b_in;
        end
    end
endmodule

// Stage 3: Term calculation module
module term_calculator (
    input wire clk,
    input wire rst_n,
    input wire a_in,
    input wire b_in,
    input wire a_neg_in,
    input wire b_neg_in,
    output reg term1_out,
    output reg term2_out
);
    // Calculate intermediate terms for XOR operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            term1_out <= 1'b0;
            term2_out <= 1'b0;
        end else begin
            term1_out <= a_in & b_neg_in;    // a & ~b
            term2_out <= a_neg_in & b_in;    // ~a & b
        end
    end
endmodule

// Stage 4: Result combination module
module result_combiner (
    input wire clk,
    input wire rst_n,
    input wire term1_in,
    input wire term2_in,
    output reg result_out
);
    // Combine terms to produce result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_out <= 1'b0;
        end else begin
            result_out <= term1_in | term2_in;
        end
    end
endmodule

// Final Stage: Output registration module
module output_register (
    input wire clk,
    input wire rst_n,
    input wire result_in,
    output reg y_out
);
    // Final output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_out <= 1'b0;
        end else begin
            y_out <= result_in;
        end
    end
endmodule