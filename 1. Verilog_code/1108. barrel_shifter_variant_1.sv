//SystemVerilog
module barrel_shifter (
    input wire [7:0] data_in,     // Input data
    input wire [2:0] shift_amt,   // Shift amount
    input wire direction,         // 0: right, 1: left
    output reg [7:0] shifted_out  // Shifted result
);

    wire [7:0] left_multiplier;
    wire [7:0] right_multiplier;
    wire [7:0] karatsuba_result;

    assign left_multiplier = data_in;

    reg [7:0] right_mult_reg;
    always @(*) begin
        if (direction)
            right_mult_reg = 8'b1 << shift_amt;
        else
            right_mult_reg = 8'b1 >> shift_amt;
    end
    assign right_multiplier = right_mult_reg;

    karatsuba_multiplier_8bit u_karatsuba_mult (
        .a(left_multiplier),
        .b(right_multiplier),
        .result(karatsuba_result)
    );

    always @(*) begin
        shifted_out = karatsuba_result;
    end

endmodule

module karatsuba_multiplier_8bit (
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

    reg [7:0] a_low_b_low;
    reg [7:0] a_high_b_high;
    reg [7:0] a_sum_b_sum;
    reg [7:0] z0, z1, z2;

    always @(*) begin
        a_low_b_low   = a_low  * b_low;
        a_high_b_high = a_high * b_high;
        a_sum_b_sum   = (a_low + a_high) * (b_low + b_high);
    end

    always @(*) begin
        z0 = a_low_b_low;
        z2 = a_high_b_high;
        z1 = a_sum_b_sum - z2 - z0;
    end

    reg [7:0] karatsuba_res_comb;
    always @(*) begin
        karatsuba_res_comb = (z2 << 8) | (z1 << 4) | z0;
    end

    assign result = karatsuba_res_comb;

endmodule