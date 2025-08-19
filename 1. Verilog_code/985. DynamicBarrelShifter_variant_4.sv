//SystemVerilog
module DynamicBarrelShifter #(
    parameter MAX_SHIFT = 4,
    parameter WIDTH     = 8
) (
    input  wire [WIDTH-1:0]      data_in,
    input  wire [MAX_SHIFT-1:0]  shift_val,
    output wire [WIDTH-1:0]      data_out
);

    // Stage 1: Barrel Shifting Stage
    wire [WIDTH-1:0] stage1_shift_left;
    wire [WIDTH-1:0] stage1_shift_right;

    assign stage1_shift_left  = data_in << shift_val;
    assign stage1_shift_right = data_in >> shift_val;

    // Pipeline Register Stage 1
    reg [WIDTH-1:0] stage2_shift_left_reg;
    reg [WIDTH-1:0] stage2_shift_right_reg;
    always @(*) begin
        stage2_shift_left_reg  = stage1_shift_left;
        stage2_shift_right_reg = stage1_shift_right;
    end

    // Stage 2: Inversion and Adder Preparation
    wire [WIDTH-1:0] stage2_shift_right_inv;
    wire [WIDTH-1:0] stage2_adder_in_b;
    wire             stage2_carry_in;
    wire             stage2_is_subtraction;

    assign stage2_is_subtraction = 1'b1;
    assign stage2_shift_right_inv = ~stage2_shift_right_reg;
    assign stage2_carry_in        = stage2_is_subtraction ? 1'b1 : 1'b0;
    assign stage2_adder_in_b      = stage2_is_subtraction ? stage2_shift_right_inv : stage2_shift_right_reg;

    // Pipeline Register Stage 2
    reg [WIDTH-1:0] stage3_shift_left_reg;
    reg [WIDTH-1:0] stage3_adder_in_b_reg;
    reg             stage3_carry_in_reg;
    always @(*) begin
        stage3_shift_left_reg = stage2_shift_left_reg;
        stage3_adder_in_b_reg = stage2_adder_in_b;
        stage3_carry_in_reg   = stage2_carry_in;
    end

    // Stage 3: Final Addition
    wire [WIDTH-1:0] stage3_subtraction_result;
    assign stage3_subtraction_result = stage3_shift_left_reg + stage3_adder_in_b_reg + stage3_carry_in_reg;

    // Output Register (optional, for further pipelining)
    reg [WIDTH-1:0] data_out_reg;
    always @(*) begin
        data_out_reg = stage3_subtraction_result;
    end

    assign data_out = data_out_reg;

endmodule