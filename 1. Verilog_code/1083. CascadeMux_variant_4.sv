//SystemVerilog
module CascadeMux (
    input  [1:0] sel1,
    input  [1:0] sel2,
    input  [3:0][3:0] stage1,
    input  [3:0][3:0] stage2,
    output reg [3:0] out
);

reg [3:0] stage1_selected;
reg [3:0] stage2_selected;

// 4-bit conditional sum subtractor
function [3:0] conditional_sum_subtract;
    input [3:0] minuend;
    input [3:0] subtrahend;
    reg [3:0] sum0, sum1;
    reg [3:0] carry0, carry1;
    reg [3:0] subtrahend_inv;
    reg carry_in;
    reg [1:0] group_carry;
    reg [3:0] s;
    begin
        // Invert subtrahend for two's complement subtraction
        subtrahend_inv = ~subtrahend;
        carry_in = 1'b1; // Two's complement add 1

        // First group (bits 1:0)
        sum0[0] = minuend[0] ^ subtrahend_inv[0] ^ 1'b0;
        carry0[0] = (minuend[0] & subtrahend_inv[0]) | (minuend[0] & 1'b0) | (subtrahend_inv[0] & 1'b0);

        sum1[0] = minuend[0] ^ subtrahend_inv[0] ^ 1'b1;
        carry1[0] = (minuend[0] & subtrahend_inv[0]) | (minuend[0] & 1'b1) | (subtrahend_inv[0] & 1'b1);

        sum0[1] = minuend[1] ^ subtrahend_inv[1] ^ carry0[0];
        carry0[1] = (minuend[1] & subtrahend_inv[1]) | (minuend[1] & carry0[0]) | (subtrahend_inv[1] & carry0[0]);

        sum1[1] = minuend[1] ^ subtrahend_inv[1] ^ carry1[0];
        carry1[1] = (minuend[1] & subtrahend_inv[1]) | (minuend[1] & carry1[0]) | (subtrahend_inv[1] & carry1[0]);

        group_carry[0] = carry_in ? carry1[1] : carry0[1];
        s[0] = carry_in ? sum1[0] : sum0[0];
        s[1] = carry_in ? sum1[1] : sum0[1];

        // Second group (bits 3:2)
        sum0[2] = minuend[2] ^ subtrahend_inv[2] ^ 1'b0;
        carry0[2] = (minuend[2] & subtrahend_inv[2]) | (minuend[2] & 1'b0) | (subtrahend_inv[2] & 1'b0);

        sum1[2] = minuend[2] ^ subtrahend_inv[2] ^ 1'b1;
        carry1[2] = (minuend[2] & subtrahend_inv[2]) | (minuend[2] & 1'b1) | (subtrahend_inv[2] & 1'b1);

        sum0[3] = minuend[3] ^ subtrahend_inv[3] ^ carry0[2];
        carry0[3] = (minuend[3] & subtrahend_inv[3]) | (minuend[3] & carry0[2]) | (subtrahend_inv[3] & carry0[2]);

        sum1[3] = minuend[3] ^ subtrahend_inv[3] ^ carry1[2];
        carry1[3] = (minuend[3] & subtrahend_inv[3]) | (minuend[3] & carry1[2]) | (subtrahend_inv[3] & carry1[2]);

        group_carry[1] = group_carry[0] ? carry1[3] : carry0[3];
        s[2] = group_carry[0] ? sum1[2] : sum0[2];
        s[3] = group_carry[0] ? sum1[3] : sum0[3];

        conditional_sum_subtract = s;
    end
endfunction

always @(*) begin
    // Select from stage1 based on sel1
    case (sel1)
        2'b00: stage1_selected = stage1[0];
        2'b01: stage1_selected = stage1[1];
        2'b10: stage1_selected = stage1[2];
        2'b11: stage1_selected = stage1[3];
        default: stage1_selected = 4'b0000;
    endcase

    // Select from stage2 based on sel2
    case (sel2)
        2'b00: stage2_selected = stage2[0];
        2'b01: stage2_selected = stage2[1];
        2'b10: stage2_selected = stage2[2];
        2'b11: stage2_selected = stage2[3];
        default: stage2_selected = 4'b0000;
    endcase

    // Output selection using conditional sum subtractor if sel1[0] is set
    if (sel1[0])
        out = conditional_sum_subtract(stage2_selected, stage1_selected);
    else
        out = stage1_selected;
end

endmodule