//SystemVerilog
module barrel_shifter (
    input wire [7:0] data_in,         // Input data
    input wire [2:0] shift_amt,       // Shift amount
    input wire direction,             // 0: right, 1: left
    output reg [7:0] shifted_out      // Shifted result
);

    wire [7:0] left_shift_stage1, left_shift_stage2, left_shift_stage3;
    wire [7:0] right_shift_stage1, right_shift_stage2, right_shift_stage3;
    wire [7:0] left_shifted, right_shifted;

    // Left shift
    assign left_shift_stage1 = shift_amt[0] ? karatsuba_multiplier_8bit({data_in[6:0], 1'b0}, 8'd1) : data_in;
    assign left_shift_stage2 = shift_amt[1] ? karatsuba_multiplier_8bit({left_shift_stage1[5:0], 2'b00}, 8'd1) : left_shift_stage1;
    assign left_shift_stage3 = shift_amt[2] ? karatsuba_multiplier_8bit({left_shift_stage2[3:0], 4'b0000}, 8'd1) : left_shift_stage2;
    assign left_shifted = left_shift_stage3;

    // Right shift
    assign right_shift_stage1 = shift_amt[0] ? karatsuba_multiplier_8bit({1'b0, data_in[7:1]}, 8'd1) : data_in;
    assign right_shift_stage2 = shift_amt[1] ? karatsuba_multiplier_8bit({2'b00, right_shift_stage1[7:2]}, 8'd1) : right_shift_stage1;
    assign right_shift_stage3 = shift_amt[2] ? karatsuba_multiplier_8bit({4'b0000, right_shift_stage2[7:4]}, 8'd1) : right_shift_stage2;
    assign right_shifted = right_shift_stage3;

    always @(*) begin
        if (direction)
            shifted_out = left_shifted;
        else
            shifted_out = right_shifted;
    end

    function [7:0] karatsuba_multiplier_8bit;
        input [7:0] a, b;
        reg [15:0] product_full;
        begin
            product_full = karatsuba_8x8(a, b);
            karatsuba_multiplier_8bit = product_full[7:0];
        end
    endfunction

    function [15:0] karatsuba_8x8;
        input [7:0] x, y;
        reg [3:0] xh, xl, yh, yl;
        reg [7:0] z0, z1, z2;
        reg [7:0] xh_plus_xl, yh_plus_yl;
        reg [15:0] result;
        begin
            xh = x[7:4];
            xl = x[3:0];
            yh = y[7:4];
            yl = y[3:0];
            z0 = karatsuba_4x4(xl, yl);
            z2 = karatsuba_4x4(xh, yh);
            xh_plus_xl = xh + xl;
            yh_plus_yl = yh + yl;
            z1 = karatsuba_4x4(xh_plus_xl[3:0], yh_plus_yl[3:0]);
            result = (z2 << 8) + ((z1 - z2 - z0) << 4) + z0;
            karatsuba_8x8 = result;
        end
    endfunction

    function [7:0] karatsuba_4x4;
        input [3:0] x, y;
        reg [1:0] xh, xl, yh, yl;
        reg [3:0] z0, z1, z2;
        reg [3:0] xh_plus_xl, yh_plus_yl;
        reg [7:0] result;
        begin
            xh = x[3:2];
            xl = x[1:0];
            yh = y[3:2];
            yl = y[1:0];
            z0 = karatsuba_2x2(xl, yl);
            z2 = karatsuba_2x2(xh, yh);
            xh_plus_xl = xh + xl;
            yh_plus_yl = yh + yl;
            z1 = karatsuba_2x2(xh_plus_xl[1:0], yh_plus_yl[1:0]);
            result = (z2 << 4) + ((z1 - z2 - z0) << 2) + z0;
            karatsuba_4x4 = result;
        end
    endfunction

    function [3:0] karatsuba_2x2;
        input [1:0] x, y;
        reg [0:0] xh, xl, yh, yl;
        reg [1:0] z0, z1, z2;
        reg [1:0] xh_plus_xl, yh_plus_yl;
        reg [3:0] result;
        begin
            xh = x[1];
            xl = x[0];
            yh = y[1];
            yl = y[0];
            z0 = xl * yl;
            z2 = xh * yh;
            xh_plus_xl = xh + xl;
            yh_plus_yl = yh + yl;
            z1 = (xh_plus_xl) * (yh_plus_yl);
            result = (z2 << 2) + ((z1 - z2 - z0) << 1) + z0;
            karatsuba_2x2 = result;
        end
    endfunction

endmodule