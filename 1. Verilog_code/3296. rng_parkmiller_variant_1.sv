//SystemVerilog
// Top-level module for Park-Miller 16-bit RNG
module rng_parkmiller_16(
    input             clk,
    input             rst,
    input             en,
    output [31:0]     rand_out
);
    // Internal signals for multiplier and modulus
    wire [63:0] mul_result;
    wire [31:0] mod_result;
    reg  [31:0] rng_state;
    reg  [31:0] rng_state_next;

    // State register update
    always @(posedge clk) begin
        if (rst)
            rng_state <= 32'd1;
        else
            rng_state <= rng_state_next;
    end

    // Next state logic
    always @(*) begin
        if (en)
            rng_state_next = mod_result;
        else
            rng_state_next = rng_state;
    end

    // Multiplier submodule instance
    rng_multiplier #(
        .WIDTH(32)
    ) u_rng_multiplier (
        .a(rng_state),
        .b(32'd16807),
        .result(mul_result)
    );

    // Modulus submodule instance
    rng_modulus #(
        .WIDTH(32)
    ) u_rng_modulus (
        .dividend(mul_result[30:0]), // Only lower 31 bits are used for modulus
        .modulus(32'd2147483647),
        .remainder(mod_result)
    );

    assign rand_out = rng_state;

endmodule

// Multiplier Submodule
// Performs multiplication of two WIDTH-bit numbers, outputs 2*WIDTH bits
module rng_multiplier #(
    parameter WIDTH = 32
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [2*WIDTH-1:0] result
);
    assign result = a * b;
endmodule

// Modulus Submodule
// Computes remainder = dividend % modulus
module rng_modulus #(
    parameter WIDTH = 32
)(
    input  [WIDTH-1:0] dividend,
    input  [WIDTH-1:0] modulus,
    output [WIDTH-1:0] remainder
);
    assign remainder = dividend % modulus;
endmodule