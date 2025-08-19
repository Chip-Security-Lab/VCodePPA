//SystemVerilog
module CascadedShifter #(parameter STAGES=3, WIDTH=8) (
    input clk,
    input en,
    input serial_in,
    output serial_out
);
    wire [STAGES:0] stage_connection;
    assign stage_connection[0] = serial_in;

    genvar stage_idx;
    generate
        for(stage_idx=0; stage_idx<STAGES; stage_idx=stage_idx+1) begin : stage_gen
            ShiftStage #(.WIDTH(WIDTH)) stage_inst(
                .clk(clk),
                .en(en),
                .in(stage_connection[stage_idx]),
                .out(stage_connection[stage_idx+1])
            );
        end
    endgenerate

    assign serial_out = stage_connection[STAGES];
endmodule

module CarryLookaheadAdder8 (
    input  [7:0] operand_a,
    input  [7:0] operand_b,
    input        carry_in,
    output [7:0] sum_out,
    output       carry_out
);
    wire [7:0] generate_term;
    wire [7:0] propagate_term;
    wire [7:0] carry_chain;

    assign generate_term = operand_a & operand_b;
    assign propagate_term = operand_a ^ operand_b;

    // Intermediate signals for carry expansion
    wire level1_1;
    wire level2_1, level2_2;
    wire level3_1, level3_2, level3_3;
    wire level4_1, level4_2, level4_3, level4_4;
    wire level5_1, level5_2, level5_3, level5_4, level5_5;
    wire level6_1, level6_2, level6_3, level6_4, level6_5, level6_6;
    wire level7_1, level7_2, level7_3, level7_4, level7_5, level7_6, level7_7;
    wire level8_1, level8_2, level8_3, level8_4, level8_5, level8_6, level8_7, level8_8;

    // Carry chain expansion using intermediate variables for better clarity and synthesis
    assign carry_chain[0] = carry_in;

    // Carry 1
    assign level1_1 = propagate_term[0] & carry_chain[0];
    assign carry_chain[1] = generate_term[0] | level1_1;

    // Carry 2
    assign level2_1 = propagate_term[1] & generate_term[0];
    assign level2_2 = propagate_term[1] & propagate_term[0] & carry_chain[0];
    assign carry_chain[2] = generate_term[1] | level2_1 | level2_2;

    // Carry 3
    assign level3_1 = propagate_term[2] & generate_term[1];
    assign level3_2 = propagate_term[2] & propagate_term[1] & generate_term[0];
    assign level3_3 = propagate_term[2] & propagate_term[1] & propagate_term[0] & carry_chain[0];
    assign carry_chain[3] = generate_term[2] | level3_1 | level3_2 | level3_3;

    // Carry 4
    assign level4_1 = propagate_term[3] & generate_term[2];
    assign level4_2 = propagate_term[3] & propagate_term[2] & generate_term[1];
    assign level4_3 = propagate_term[3] & propagate_term[2] & propagate_term[1] & generate_term[0];
    assign level4_4 = propagate_term[3] & propagate_term[2] & propagate_term[1] & propagate_term[0] & carry_chain[0];
    assign carry_chain[4] = generate_term[3] | level4_1 | level4_2 | level4_3 | level4_4;

    // Carry 5
    assign level5_1 = propagate_term[4] & generate_term[3];
    assign level5_2 = propagate_term[4] & propagate_term[3] & generate_term[2];
    assign level5_3 = propagate_term[4] & propagate_term[3] & propagate_term[2] & generate_term[1];
    assign level5_4 = propagate_term[4] & propagate_term[3] & propagate_term[2] & propagate_term[1] & generate_term[0];
    assign level5_5 = propagate_term[4] & propagate_term[3] & propagate_term[2] & propagate_term[1] & propagate_term[0] & carry_chain[0];
    assign carry_chain[5] = generate_term[4] | level5_1 | level5_2 | level5_3 | level5_4 | level5_5;

    // Carry 6
    assign level6_1 = propagate_term[5] & generate_term[4];
    assign level6_2 = propagate_term[5] & propagate_term[4] & generate_term[3];
    assign level6_3 = propagate_term[5] & propagate_term[4] & propagate_term[3] & generate_term[2];
    assign level6_4 = propagate_term[5] & propagate_term[4] & propagate_term[3] & propagate_term[2] & generate_term[1];
    assign level6_5 = propagate_term[5] & propagate_term[4] & propagate_term[3] & propagate_term[2] & propagate_term[1] & generate_term[0];
    assign level6_6 = propagate_term[5] & propagate_term[4] & propagate_term[3] & propagate_term[2] & propagate_term[1] & propagate_term[0] & carry_chain[0];
    assign carry_chain[6] = generate_term[5] | level6_1 | level6_2 | level6_3 | level6_4 | level6_5 | level6_6;

    // Carry 7
    assign level7_1 = propagate_term[6] & generate_term[5];
    assign level7_2 = propagate_term[6] & propagate_term[5] & generate_term[4];
    assign level7_3 = propagate_term[6] & propagate_term[5] & propagate_term[4] & generate_term[3];
    assign level7_4 = propagate_term[6] & propagate_term[5] & propagate_term[4] & propagate_term[3] & generate_term[2];
    assign level7_5 = propagate_term[6] & propagate_term[5] & propagate_term[4] & propagate_term[3] & propagate_term[2] & generate_term[1];
    assign level7_6 = propagate_term[6] & propagate_term[5] & propagate_term[4] & propagate_term[3] & propagate_term[2] & propagate_term[1] & generate_term[0];
    assign level7_7 = propagate_term[6] & propagate_term[5] & propagate_term[4] & propagate_term[3] & propagate_term[2] & propagate_term[1] & propagate_term[0] & carry_chain[0];
    assign carry_chain[7] = generate_term[6] | level7_1 | level7_2 | level7_3 | level7_4 | level7_5 | level7_6 | level7_7;

    // Carry out
    assign level8_1 = propagate_term[7] & generate_term[6];
    assign level8_2 = propagate_term[7] & propagate_term[6] & generate_term[5];
    assign level8_3 = propagate_term[7] & propagate_term[6] & propagate_term[5] & generate_term[4];
    assign level8_4 = propagate_term[7] & propagate_term[6] & propagate_term[5] & propagate_term[4] & generate_term[3];
    assign level8_5 = propagate_term[7] & propagate_term[6] & propagate_term[5] & propagate_term[4] & propagate_term[3] & generate_term[2];
    assign level8_6 = propagate_term[7] & propagate_term[6] & propagate_term[5] & propagate_term[4] & propagate_term[3] & propagate_term[2] & generate_term[1];
    assign level8_7 = propagate_term[7] & propagate_term[6] & propagate_term[5] & propagate_term[4] & propagate_term[3] & propagate_term[2] & propagate_term[1] & generate_term[0];
    assign level8_8 = propagate_term[7] & propagate_term[6] & propagate_term[5] & propagate_term[4] & propagate_term[3] & propagate_term[2] & propagate_term[1] & propagate_term[0] & carry_chain[0];
    assign carry_out = generate_term[7] | level8_1 | level8_2 | level8_3 | level8_4 | level8_5 | level8_6 | level8_7 | level8_8;

    assign sum_out = propagate_term ^ carry_chain;
endmodule

module ShiftStage #(parameter WIDTH=8) (
    input clk,
    input en,
    input in,
    output reg out
);
    reg [WIDTH-1:0] shift_register;
    wire [WIDTH-1:0] shifted_value;
    wire [WIDTH-1:0] adder_sum;
    wire             adder_carry;

    assign shifted_value = {shift_register[WIDTH-2:0], in};

    CarryLookaheadAdder8 adder_inst (
        .operand_a(shift_register),
        .operand_b(shifted_value),
        .carry_in(1'b0),
        .sum_out(adder_sum),
        .carry_out(adder_carry)
    );

    always @(posedge clk) begin
        if (en)
            shift_register <= adder_sum;
        out <= shift_register[WIDTH-1];
    end
endmodule