//SystemVerilog
module bidir_shifter(
    input  wire        clk,
    input  wire        reset_n,
    input  wire [7:0]  data_in,
    input  wire [2:0]  shift_amount,
    input  wire        left_right_n,    // 1=left, 0=right
    input  wire        arithmetic_n,    // 1=arithmetic, 0=logical (right only)
    output reg  [7:0]  data_out
);

    // Forward retiming: move registers after barrel shifter logic

    wire [7:0] left_shift_stage0, left_shift_stage1, left_shift_stage2;
    wire [7:0] right_shift_stage0, right_shift_stage1, right_shift_stage2;
    wire [7:0] arith_shift_stage0, arith_shift_stage1, arith_shift_stage2;
    wire [7:0] left_shift_result_comb;
    wire [7:0] right_shift_result_comb;
    wire [7:0] arith_shift_result_comb;
    wire       sign_bit_comb;

    // Barrel shifter logic directly from inputs
    assign left_shift_stage0  = shift_amount[0] ? {data_in[6:0], 1'b0} : data_in;
    assign left_shift_stage1  = shift_amount[1] ? {left_shift_stage0[5:0], 2'b00} : left_shift_stage0;
    assign left_shift_stage2  = shift_amount[2] ? {left_shift_stage1[3:0], 4'b0000} : left_shift_stage1;
    assign left_shift_result_comb = left_shift_stage2;

    assign right_shift_stage0 = shift_amount[0] ? {1'b0, data_in[7:1]} : data_in;
    assign right_shift_stage1 = shift_amount[1] ? {2'b00, right_shift_stage0[7:2]} : right_shift_stage0;
    assign right_shift_stage2 = shift_amount[2] ? {4'b0000, right_shift_stage1[7:4]} : right_shift_stage1;
    assign right_shift_result_comb = right_shift_stage2;

    assign sign_bit_comb = data_in[7];
    assign arith_shift_stage0 = shift_amount[0] ? {sign_bit_comb, data_in[7:1]} : data_in;
    assign arith_shift_stage1 = shift_amount[1] ? {{2{sign_bit_comb}}, arith_shift_stage0[7:2]} : arith_shift_stage0;
    assign arith_shift_stage2 = shift_amount[2] ? {{4{sign_bit_comb}}, arith_shift_stage1[7:4]} : arith_shift_stage1;
    assign arith_shift_result_comb = arith_shift_stage2;

    // Insert pipeline registers after combination logic
    reg [7:0] left_shift_result_reg;
    reg [7:0] right_shift_result_reg;
    reg [7:0] arith_shift_result_reg;
    reg       left_right_n_reg;
    reg       arithmetic_n_reg;
    reg       sign_bit_reg;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            left_shift_result_reg   <= 8'h00;
            right_shift_result_reg  <= 8'h00;
            arith_shift_result_reg  <= 8'h00;
            left_right_n_reg        <= 1'b0;
            arithmetic_n_reg        <= 1'b0;
            sign_bit_reg            <= 1'b0;
        end else begin
            left_shift_result_reg   <= left_shift_result_comb;
            right_shift_result_reg  <= right_shift_result_comb;
            arith_shift_result_reg  <= arith_shift_result_comb;
            left_right_n_reg        <= left_right_n;
            arithmetic_n_reg        <= arithmetic_n;
            sign_bit_reg            <= sign_bit_comb;
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            data_out <= 8'h00;
        else if (left_right_n_reg)
            data_out <= left_shift_result_reg;
        else if (arithmetic_n_reg && sign_bit_reg)
            data_out <= arith_shift_result_reg;
        else
            data_out <= right_shift_result_reg;
    end

endmodule