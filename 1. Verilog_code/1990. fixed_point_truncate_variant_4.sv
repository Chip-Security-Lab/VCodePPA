//SystemVerilog
module fixed_point_truncate #(parameter IN_WIDTH=16, OUT_WIDTH=8)(
    input wire [IN_WIDTH-1:0] in_data,
    output reg [OUT_WIDTH-1:0] out_data,
    output reg overflow
);
    wire sign_bit = in_data[IN_WIDTH-1];

    wire [15:0] lut_sub_a;
    wire [15:0] lut_sub_b;
    wire [15:0] lut_sub_result;

    // LUT for 4-bit subtraction
    reg [3:0] lut_diff [0:15][0:15];

    integer i, j;

    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                lut_diff[i][j] = i - j;
            end
        end
    end

    // 16-bit subtraction using LUTs (nibble-wise)
    function [15:0] lut_subtract_16;
        input [15:0] a;
        input [15:0] b;
        reg [3:0] diff0, diff1, diff2, diff3;
        reg borrow0, borrow1, borrow2, borrow3;
        reg [3:0] a0, a1, a2, a3;
        reg [3:0] b0, b1, b2, b3;
        begin
            a0 = a[3:0];   b0 = b[3:0];
            a1 = a[7:4];   b1 = b[7:4];
            a2 = a[11:8];  b2 = b[11:8];
            a3 = a[15:12]; b3 = b[15:12];

            // Subtract lowest nibble
            if (a0 >= b0) begin
                diff0 = lut_diff[a0][b0];
                borrow0 = 1'b0;
            end else begin
                diff0 = lut_diff[a0 + 16][b0];
                borrow0 = 1'b1;
            end

            // Subtract next nibble with borrow
            if (a1 >= (b1 + borrow0)) begin
                diff1 = lut_diff[a1][b1 + borrow0];
                borrow1 = 1'b0;
            end else begin
                diff1 = lut_diff[a1 + 16][b1 + borrow0];
                borrow1 = 1'b1;
            end

            // Subtract next nibble with borrow
            if (a2 >= (b2 + borrow1)) begin
                diff2 = lut_diff[a2][b2 + borrow1];
                borrow2 = 1'b0;
            end else begin
                diff2 = lut_diff[a2 + 16][b2 + borrow1];
                borrow2 = 1'b1;
            end

            // Subtract highest nibble with borrow
            if (a3 >= (b3 + borrow2)) begin
                diff3 = lut_diff[a3][b3 + borrow2];
                borrow3 = 1'b0;
            end else begin
                diff3 = lut_diff[a3 + 16][b3 + borrow2];
                borrow3 = 1'b1;
            end

            lut_subtract_16 = {diff3, diff2, diff1, diff0};
        end
    endfunction

    always @* begin
        if (OUT_WIDTH >= IN_WIDTH) begin
            out_data = {{(OUT_WIDTH-IN_WIDTH){sign_bit}}, in_data};
            overflow = 1'b0;
        end else begin
            // LUT-based subtraction for overflow detection
            // overflow = (|in_data[IN_WIDTH-1:OUT_WIDTH]) ^ sign;
            // Using LUT-based subtraction to compute in_data[IN_WIDTH-1:OUT_WIDTH] - 0
            // If result is non-zero, set a flag
            reg [IN_WIDTH-OUT_WIDTH-1:0] trunc_bits;
            reg trunc_nonzero;
            integer k;
            trunc_bits = in_data[IN_WIDTH-1:OUT_WIDTH];
            trunc_nonzero = 1'b0;
            for (k = 0; k < IN_WIDTH-OUT_WIDTH; k = k + 1) begin
                if (trunc_bits[k] == 1'b1)
                    trunc_nonzero = 1'b1;
            end
            out_data = in_data[OUT_WIDTH-1:0];
            overflow = trunc_nonzero ^ sign_bit;
        end
    end
endmodule