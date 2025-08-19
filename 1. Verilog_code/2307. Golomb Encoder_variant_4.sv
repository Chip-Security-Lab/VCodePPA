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
    wire [15:0] quotient_pre;
    wire [15:0] remainder_pre;
    wire        enable_r;
    
    // Submodule for pre-computation stage
    value_preprocessor #(
        .M_POWER(M_POWER)
    ) pre_compute_unit (
        .i_clk        (i_clk),
        .i_enable     (i_enable),
        .i_value      (i_value),
        .o_quotient   (quotient_pre),
        .o_remainder  (remainder_pre),
        .o_enable_r   (enable_r)
    );
    
    // Submodule for code generation stage
    code_generator #(
        .M_POWER(M_POWER)
    ) code_gen_unit (
        .i_clk        (i_clk),
        .i_enable_r   (enable_r),
        .i_quotient   (quotient_pre),
        .i_remainder  (remainder_pre),
        .o_valid      (o_valid),
        .o_code       (o_code),
        .o_len        (o_len)
    );
endmodule

// Preprocessor module for computing quotient and remainder
module value_preprocessor #(
    parameter M_POWER = 2
)(
    input              i_clk,
    input              i_enable,
    input       [15:0] i_value,
    output reg  [15:0] o_quotient,
    output reg  [15:0] o_remainder,
    output reg         o_enable_r
);
    // Mask for calculating remainder
    wire [15:0] remainder_mask = (1 << M_POWER) - 1;
    
    always @(posedge i_clk) begin
        // Compute quotient (value divided by 2^M_POWER)
        o_quotient <= i_value >> M_POWER;
        
        // Compute remainder (value modulo 2^M_POWER)
        o_remainder <= i_value & remainder_mask;
        
        // Register enable signal
        o_enable_r <= i_enable;
    end
endmodule

// Code generator module for producing Golomb code
module code_generator #(
    parameter M_POWER = 2
)(
    input             i_clk,
    input             i_enable_r,
    input      [15:0] i_quotient,
    input      [15:0] i_remainder,
    output reg        o_valid,
    output reg [31:0] o_code,
    output reg [5:0]  o_len
);
    always @(posedge i_clk) begin
        if (i_enable_r) begin
            // Generate unary prefix (quotient 1's followed by a 0)
            // followed by binary coded remainder
            o_code <= {{16{1'b1}} >> (16-i_quotient), 1'b0, i_remainder};
            
            // Total code length = unary prefix length + separator bit + remainder bits
            o_len <= i_quotient + 1 + M_POWER;
            
            // Signal valid output
            o_valid <= 1'b1;
        end else begin
            o_valid <= 1'b0;
        end
    end
endmodule