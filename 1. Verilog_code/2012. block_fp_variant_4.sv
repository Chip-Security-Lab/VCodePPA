//SystemVerilog
module block_fp #(
    parameter N = 4,
    parameter W = 16
)(
    input  [W-1:0] in_array [0:N-1],
    output [W+3:0] out_array [0:N-1],
    output [3:0]   exp
);
    reg [3:0] max_exp;
    integer i;

    // Log2 calculation function
    function [3:0] log2_func;
        input [W-1:0] value;
        integer j;
        reg found;
        begin
            log2_func = 0;
            found = 0;
            for (j = W-1; j >= 0; j = j - 1) begin
                if (value[j] && !found) begin
                    log2_func = j;
                    found = 1;
                end
            end
        end
    endfunction

    // Binary two's complement subtractor for 4 bits
    function [3:0] twos_complement_sub;
        input [3:0] minuend;
        input [3:0] subtrahend;
        reg [3:0] subtrahend_inv;
        reg       carry_in;
        reg [4:0] sum_with_carry;
        begin
            subtrahend_inv = ~subtrahend;
            carry_in = 1'b1;
            sum_with_carry = {1'b0, minuend} + {1'b0, subtrahend_inv} + carry_in;
            twos_complement_sub = sum_with_carry[3:0];
        end
    endfunction

    always @(*) begin
        max_exp = log2_func(in_array[0]);
        for (i = 1; i < N; i = i + 1) begin
            if (log2_func(in_array[i]) > max_exp)
                max_exp = log2_func(in_array[i]);
        end
    end

    assign exp = max_exp;

    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : gen_output
            wire [3:0] shift_amount;
            wire [W-1:0] in_val;
            wire [W+3:0] shifted_val_stage0;
            wire [W+3:0] shifted_val_stage1;
            wire [W+3:0] shifted_val_stage2;
            wire [W+3:0] shifted_val_stage3;
            wire [W+3:0] shifted_val_stage4;

            assign in_val = in_array[g];
            assign shift_amount = twos_complement_sub(max_exp, log2_func(in_val));

            // Stage 0: input extension
            assign shifted_val_stage0 = { {4{1'b0}}, in_val };

            // Stage 1: shift by 1 if shift_amount[0]
            assign shifted_val_stage1 = shift_amount[0] ? {shifted_val_stage0[W+2:0], 1'b0} : shifted_val_stage0;

            // Stage 2: shift by 2 if shift_amount[1]
            assign shifted_val_stage2 = shift_amount[1] ? {shifted_val_stage1[W+1:0], 2'b00} : shifted_val_stage1;

            // Stage 3: shift by 4 if shift_amount[2]
            assign shifted_val_stage3 = shift_amount[2] ? {shifted_val_stage2[W-1:0], 4'b0000} : shifted_val_stage2;

            // Stage 4: shift by 8 if shift_amount[3]
            assign shifted_val_stage4 = shift_amount[3] ? {shifted_val_stage3[W-9:0], 8'b00000000} : shifted_val_stage3;

            assign out_array[g] = shifted_val_stage4;
        end
    endgenerate
endmodule