//SystemVerilog
module multifunction_shifter (
    input  wire [31:0] operand,
    input  wire [4:0]  shift_amt,
    input  wire [1:0]  operation, // 00=logical, 01=arithmetic, 10=rotate, 11=special
    output wire [31:0] shifted
);

    // Stage 1: Input register stage (optional for pipelining, can be removed if not required)
    wire [31:0] operand_stage1;
    wire [4:0]  shift_amt_stage1;
    wire [1:0]  operation_stage1;

    assign operand_stage1   = operand;
    assign shift_amt_stage1 = shift_amt;
    assign operation_stage1 = operation;

    // Stage 2: Barrel shifter implementation for all shift operations

    // Logical right shift using barrel shifter
    wire [31:0] logical_shift_stage2_1, logical_shift_stage2_2, logical_shift_stage2_3, logical_shift_stage2_4, logical_shift_stage2_5;

    assign logical_shift_stage2_1 = shift_amt_stage1[0] ? {1'b0, operand_stage1[31:1]}    : operand_stage1;
    assign logical_shift_stage2_2 = shift_amt_stage1[1] ? {2'b0, logical_shift_stage2_1[31:2]}  : logical_shift_stage2_1;
    assign logical_shift_stage2_3 = shift_amt_stage1[2] ? {4'b0, logical_shift_stage2_2[31:4]}  : logical_shift_stage2_2;
    assign logical_shift_stage2_4 = shift_amt_stage1[3] ? {8'b0, logical_shift_stage2_3[31:8]}  : logical_shift_stage2_3;
    assign logical_shift_stage2_5 = shift_amt_stage1[4] ? {16'b0, logical_shift_stage2_4[31:16]}: logical_shift_stage2_4;
    wire [31:0] logical_shift_result_stage2;
    assign logical_shift_result_stage2 = logical_shift_stage2_5;

    // Arithmetic right shift using barrel shifter
    wire signed [31:0] signed_operand_stage1;
    assign signed_operand_stage1 = operand_stage1;
    wire [31:0] arithmetic_shift_stage2_1, arithmetic_shift_stage2_2, arithmetic_shift_stage2_3, arithmetic_shift_stage2_4, arithmetic_shift_stage2_5;

    assign arithmetic_shift_stage2_1 = shift_amt_stage1[0] ? {signed_operand_stage1[31], signed_operand_stage1[31:1]} : signed_operand_stage1;
    assign arithmetic_shift_stage2_2 = shift_amt_stage1[1] ? {{2{arithmetic_shift_stage2_1[31]}}, arithmetic_shift_stage2_1[31:2]} : arithmetic_shift_stage2_1;
    assign arithmetic_shift_stage2_3 = shift_amt_stage1[2] ? {{4{arithmetic_shift_stage2_2[31]}}, arithmetic_shift_stage2_2[31:4]} : arithmetic_shift_stage2_2;
    assign arithmetic_shift_stage2_4 = shift_amt_stage1[3] ? {{8{arithmetic_shift_stage2_3[31]}}, arithmetic_shift_stage2_3[31:8]} : arithmetic_shift_stage2_3;
    assign arithmetic_shift_stage2_5 = shift_amt_stage1[4] ? {{16{arithmetic_shift_stage2_4[31]}}, arithmetic_shift_stage2_4[31:16]} : arithmetic_shift_stage2_4;
    wire [31:0] arithmetic_shift_result_stage2;
    assign arithmetic_shift_result_stage2 = arithmetic_shift_stage2_5;

    // Rotate right shift using barrel shifter
    wire [31:0] rotate_stage2_1, rotate_stage2_2, rotate_stage2_3, rotate_stage2_4, rotate_stage2_5;

    assign rotate_stage2_1 = shift_amt_stage1[0] ? {operand_stage1[0], operand_stage1[31:1]} : operand_stage1;
    assign rotate_stage2_2 = shift_amt_stage1[1] ? {rotate_stage2_1[1:0], rotate_stage2_1[31:2]} : rotate_stage2_1;
    assign rotate_stage2_3 = shift_amt_stage1[2] ? {rotate_stage2_2[3:0], rotate_stage2_2[31:4]} : rotate_stage2_2;
    assign rotate_stage2_4 = shift_amt_stage1[3] ? {rotate_stage2_3[7:0], rotate_stage2_3[31:8]} : rotate_stage2_3;
    assign rotate_stage2_5 = shift_amt_stage1[4] ? {rotate_stage2_4[15:0], rotate_stage2_4[31:16]} : rotate_stage2_4;
    wire [31:0] rotate_right_result_stage2;
    assign rotate_right_result_stage2 = rotate_stage2_5;

    // Byte swap
    wire [31:0] byte_swap_result_stage2;
    assign byte_swap_result_stage2 = {operand_stage1[15:0], operand_stage1[31:16]};

    // Stage 3: Pipeline register for each operation result (combinational in this version)
    wire [31:0] logical_shift_result_stage3;
    wire [31:0] arithmetic_shift_result_stage3;
    wire [31:0] rotate_right_result_stage3;
    wire [31:0] byte_swap_result_stage3;

    assign logical_shift_result_stage3    = logical_shift_result_stage2;
    assign arithmetic_shift_result_stage3 = arithmetic_shift_result_stage2;
    assign rotate_right_result_stage3     = rotate_right_result_stage2;
    assign byte_swap_result_stage3        = byte_swap_result_stage2;

    // Stage 4: Multiplexer selects the correct output based on operation
    reg [31:0] shifted_stage4;
    always @(*) begin
        case (operation_stage1)
            2'b00: shifted_stage4 = logical_shift_result_stage3;     // Logical right
            2'b01: shifted_stage4 = arithmetic_shift_result_stage3;  // Arithmetic right
            2'b10: shifted_stage4 = rotate_right_result_stage3;      // Rotate right
            2'b11: shifted_stage4 = byte_swap_result_stage3;         // Byte swap
            default: shifted_stage4 = 32'b0;
        endcase
    end

    // Stage 5: Output register (optional for pipelining, can be removed if not required)
    assign shifted = shifted_stage4;

endmodule