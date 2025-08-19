//SystemVerilog
module golomb_encoder #(
    parameter M_POWER = 2  // M = 2^M_POWER
)(
    input             i_clk,
    input             i_enable,
    input      [15:0] i_value,
    output            o_valid,
    output     [31:0] o_code,
    output     [5:0]  o_len
);
    // Internal signals for connecting submodules
    wire [15:0] quotient;
    wire [15:0] remainder;
    wire        calc_valid;
    
    // Instantiate divider submodule with optimized timing
    golomb_divider #(
        .M_POWER(M_POWER)
    ) divider_inst (
        .i_clk(i_clk),
        .i_enable(i_enable),
        .i_value(i_value),
        .o_quotient(quotient),
        .o_remainder(remainder),
        .o_valid(calc_valid)
    );
    
    // Instantiate codeword generator submodule
    golomb_codeword_generator #(
        .M_POWER(M_POWER)
    ) codeword_gen_inst (
        .i_clk(i_clk),
        .i_valid(calc_valid),
        .i_quotient(quotient),
        .i_remainder(remainder),
        .o_code(o_code),
        .o_len(o_len),
        .o_valid(o_valid)
    );
    
endmodule

// Divider module - Calculates quotient and remainder
module golomb_divider #(
    parameter M_POWER = 2  // M = 2^M_POWER
)(
    input             i_clk,
    input             i_enable,
    input      [15:0] i_value,
    output     [15:0] o_quotient,
    output     [15:0] o_remainder,
    output reg        o_valid
);
    // Pre-compute divisor mask for efficient division
    wire [15:0] divisor_mask;
    assign divisor_mask = (1 << M_POWER) - 1;
    
    // Direct combinational logic for division
    wire [15:0] quotient_comb;
    wire [15:0] remainder_comb;
    
    assign quotient_comb = i_value >> M_POWER;
    assign remainder_comb = i_value & divisor_mask;
    
    // Register outputs
    reg [15:0] quotient_reg;
    reg [15:0] remainder_reg;
    
    assign o_quotient = quotient_reg;
    assign o_remainder = remainder_reg;
    
    always @(posedge i_clk) begin
        if (i_enable) begin
            quotient_reg <= quotient_comb;
            remainder_reg <= remainder_comb;
            o_valid <= 1'b1;
        end else begin
            o_valid <= 1'b0;
        end
    end
endmodule

// Codeword generator module - Creates Golomb code from quotient and remainder
module golomb_codeword_generator #(
    parameter M_POWER = 2  // M = 2^M_POWER
)(
    input             i_clk,
    input             i_valid,
    input      [15:0] i_quotient,
    input      [15:0] i_remainder,
    output reg [31:0] o_code,
    output reg [5:0]  o_len,
    output reg        o_valid
);
    // Unary part generation
    wire [15:0] unary_code_comb;
    wire [31:0] code_comb;
    wire [5:0]  len_comb;
    
    // Combinational logic for code generation
    assign unary_code_comb = {16{1'b1}} >> (16-i_quotient);
    assign code_comb = {unary_code_comb, 1'b0, i_remainder};
    assign len_comb = i_quotient + 1 + M_POWER;
    
    always @(posedge i_clk) begin
        if (i_valid) begin
            o_code <= code_comb;
            o_len <= len_comb;
            o_valid <= 1'b1;
        end else begin
            o_valid <= 1'b0;
        end
    end
endmodule