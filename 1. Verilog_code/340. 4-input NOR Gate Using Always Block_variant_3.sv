//SystemVerilog
// Top-level module: Hierarchical NOR4 with 8-bit shift-add multiplier
module nor4_always (
    input  wire A,
    input  wire B,
    input  wire C,
    input  wire D,
    output wire Y
);

    // Internal signals
    wire [7:0] multiplicand;
    wire [7:0] multiplier;
    wire [15:0] product;
    wire        nor_result;

    // Operand Generation Submodule
    operand_gen u_operand_gen (
        .in_A   (A),
        .in_B   (B),
        .out_multiplicand (multiplicand),
        .out_multiplier   (multiplier)
    );

    // 8-bit Shift-Add Multiplier Submodule
    shift_add_mult #(
        .WIDTH (8)
    ) u_shift_add_mult (
        .multiplicand (multiplicand),
        .multiplier   (multiplier),
        .product      (product)
    );

    // NOR Logic Submodule
    nor_logic u_nor_logic (
        .product_lsb (product[3:0]),
        .C           (C),
        .D           (D),
        .Y           (nor_result)
    );

    assign Y = nor_result;

endmodule

// -----------------------------------------------------------------------------
// Operand Generation Module
// Expands single-bit A and B into 8-bit operands for multiplication
// -----------------------------------------------------------------------------
module operand_gen (
    input  wire in_A,
    input  wire in_B,
    output wire [7:0] out_multiplicand,
    output wire [7:0] out_multiplier
);
    assign out_multiplicand = {8{in_A}};
    assign out_multiplier   = {8{in_B}};
endmodule

// -----------------------------------------------------------------------------
// 8-bit Shift-Add Multiplier Module (Parameterizable)
// Performs multiplication using shift-and-add method
// -----------------------------------------------------------------------------
module shift_add_mult #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] multiplicand,
    input  wire [WIDTH-1:0] multiplier,
    output reg  [2*WIDTH-1:0] product
);
    integer i;
    always @(*) begin
        product = {2*WIDTH{1'b0}};
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (multiplier[i])
                product = product + (multiplicand << i);
        end
    end
endmodule

// -----------------------------------------------------------------------------
// NOR Logic Module
// Computes NOR of the lower 4 bits of product and inputs C, D
// -----------------------------------------------------------------------------
module nor_logic (
    input  wire [3:0] product_lsb,
    input  wire       C,
    input  wire       D,
    output reg        Y
);
    always @(*) begin
        Y = ~(product_lsb[0] | product_lsb[1] | product_lsb[2] | product_lsb[3] | C | D);
    end
endmodule