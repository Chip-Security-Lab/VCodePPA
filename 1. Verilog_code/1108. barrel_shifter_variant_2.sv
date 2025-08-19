//SystemVerilog
module barrel_shifter (
    input wire [7:0] data_in,         // Input data
    input wire [2:0] shift_amt,       // Shift amount
    input wire direction,             // 0: right, 1: left
    output reg [7:0] shifted_out      // Shifted result
);

    wire [7:0] karatsuba_left_result;
    wire [7:0] karatsuba_right_result;
    wire [7:0] left_multiplier;
    wire [7:0] right_multiplier;

    // Generate left shift multiplier: 2^shift_amt
    reg [7:0] left_multiplier_reg;
    always @(*) begin
        if (shift_amt == 3'd0) begin
            left_multiplier_reg = 8'd1;
        end else if (shift_amt == 3'd1) begin
            left_multiplier_reg = 8'd2;
        end else if (shift_amt == 3'd2) begin
            left_multiplier_reg = 8'd4;
        end else if (shift_amt == 3'd3) begin
            left_multiplier_reg = 8'd8;
        end else if (shift_amt == 3'd4) begin
            left_multiplier_reg = 8'd16;
        end else if (shift_amt == 3'd5) begin
            left_multiplier_reg = 8'd32;
        end else if (shift_amt == 3'd6) begin
            left_multiplier_reg = 8'd64;
        end else begin
            left_multiplier_reg = 8'd128;
        end
    end
    assign left_multiplier = left_multiplier_reg;

    // Generate right shift multiplier: 2^(7-shift_amt+1)
    reg [7:0] right_multiplier_reg;
    always @(*) begin
        if (shift_amt == 3'd0) begin
            right_multiplier_reg = 8'd128;
        end else if (shift_amt == 3'd1) begin
            right_multiplier_reg = 8'd64;
        end else if (shift_amt == 3'd2) begin
            right_multiplier_reg = 8'd32;
        end else if (shift_amt == 3'd3) begin
            right_multiplier_reg = 8'd16;
        end else if (shift_amt == 3'd4) begin
            right_multiplier_reg = 8'd8;
        end else if (shift_amt == 3'd5) begin
            right_multiplier_reg = 8'd4;
        end else if (shift_amt == 3'd6) begin
            right_multiplier_reg = 8'd2;
        end else begin
            right_multiplier_reg = 8'd1;
        end
    end
    assign right_multiplier = right_multiplier_reg;

    // Karatsuba Multiplier for left shift (equivalent to data_in * 2^shift_amt)
    karatsuba_mult_8x8 u_karatsuba_left (
        .a      (data_in),
        .b      (left_multiplier),
        .result (karatsuba_left_result)
    );

    // Karatsuba Multiplier for right shift (equivalent to data_in * 2^(7-shift_amt+1)), then select high bits
    wire [15:0] karatsuba_right_full_result;
    karatsuba_mult_8x8 u_karatsuba_right (
        .a      (data_in),
        .b      (right_multiplier),
        .result (karatsuba_right_full_result[7:0])
    );
    assign karatsuba_right_full_result[15:8] = 8'd0;

    always @(*) begin
        if (direction) begin
            shifted_out = karatsuba_left_result;
        end else begin
            shifted_out = data_in >> shift_amt;
        end
    end

endmodule

module karatsuba_mult_8x8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] result
);
    wire [3:0] a_high;
    wire [3:0] a_low;
    wire [3:0] b_high;
    wire [3:0] b_low;

    assign a_high = a[7:4];
    assign a_low  = a[3:0];
    assign b_high = b[7:4];
    assign b_low  = b[3:0];

    wire [7:0] z0;
    wire [7:0] z1;
    wire [7:0] z2;

    assign z0 = a_low * b_low;
    assign z2 = a_high * b_high;

    wire [4:0] sum_a;
    wire [4:0] sum_b;
    wire [9:0] z1_mult;

    assign sum_a = a_low + a_high;
    assign sum_b = b_low + b_high;
    assign z1_mult = sum_a * sum_b;
    assign z1 = z1_mult - z2 - z0;

    assign result = (z2 << 8) | (z1 << 4) | z0;

endmodule