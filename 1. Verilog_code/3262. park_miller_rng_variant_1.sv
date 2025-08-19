//SystemVerilog
// Top-level Park-Miller Random Number Generator
module park_miller_rng (
    input  wire        clk,
    input  wire        rst,
    output reg  [31:0] rand_val
);

    // Internal signals for submodule connections
    wire [31:0] mod_q_result;
    wire [31:0] div_q_result;
    wire [31:0] mul_a_modq_result;
    wire [31:0] mul_mdivq_divq_result;
    reg  [31:0] sub_result_reg;
    reg  [31:0] next_rand_val_reg;
    reg         temp_le_zero_reg;

    // Park-Miller constants
    localparam [31:0] A = 16807;
    localparam [31:0] M = 32'h7FFFFFFF; // 2^31 - 1
    localparam [31:0] Q = 127773;       // M / A
    localparam [31:0] R = 2836;         // M % A
    localparam [31:0] M_DIV_Q = M / Q;

    // Submodule: Compute rand_val % Q
    mod_unit #(.WIDTH(32)) u_mod_q (
        .a(rand_val),
        .b(Q),
        .result(mod_q_result)
    );

    // Submodule: Compute rand_val / Q
    div_unit #(.WIDTH(32)) u_div_q (
        .a(rand_val),
        .b(Q),
        .result(div_q_result)
    );

    // Submodule: Compute A * (rand_val % Q)
    mul_unit #(.WIDTH(32)) u_mul_a_modq (
        .a(A),
        .b(mod_q_result),
        .result(mul_a_modq_result)
    );

    // Submodule: Compute (M / Q) * (rand_val / Q)
    mul_unit #(.WIDTH(32)) u_mul_mdivq_divq (
        .a(M_DIV_Q),
        .b(div_q_result),
        .result(mul_mdivq_divq_result)
    );

    // Submodule: Unsigned subtraction
    // Registers sub_result_reg = mul_a_modq_result - mul_mdivq_divq_result
    always @(posedge clk) begin
        sub_result_reg <= mul_a_modq_result - mul_mdivq_divq_result;
    end

    // Submodule: Less-than-or-equal-to-zero check
    // Registers temp_le_zero_reg
    always @(posedge clk) begin
        temp_le_zero_reg <= (sub_result_reg[31] == 1'b1) || (sub_result_reg == 32'd0);
    end

    // Register next_rand_val_reg
    always @(posedge clk) begin
        next_rand_val_reg <= sub_result_reg;
    end

    // Next random value selection logic
    always @(posedge clk) begin
        if (rst)
            rand_val <= 32'd1;
        else if (temp_le_zero_reg)
            rand_val <= next_rand_val_reg + M;
        else
            rand_val <= next_rand_val_reg;
    end

endmodule

// Submodule: Unsigned modulo operation
// Computes result = a % b
module mod_unit #(
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] result
);
    assign result = a % b;
endmodule

// Submodule: Unsigned division operation
// Computes result = a / b
module div_unit #(
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] result
);
    assign result = a / b;
endmodule

// Submodule: Unsigned multiplication
// Computes result = a * b
module mul_unit #(
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] result
);
    assign result = a * b;
endmodule