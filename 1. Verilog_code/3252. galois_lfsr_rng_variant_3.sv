//SystemVerilog
module galois_lfsr_rng (
    input wire clock,
    input wire reset,
    input wire enable,
    output reg [7:0] rand_data
);

    reg [7:0] lfsr_next;

    // 基拉斯基乘法器子模块实例化
    wire [7:0] karatsuba_a;
    wire [7:0] karatsuba_b;
    wire [15:0] karatsuba_result;

    assign karatsuba_a = rand_data;
    assign karatsuba_b = 8'hB8; // 0b10111000, 用于LFSR反馈的仿射变换

    karatsuba_multiplier_8bit u_karatsuba_multiplier (
        .a(karatsuba_a),
        .b(karatsuba_b),
        .product(karatsuba_result)
    );

    // LFSR next state logic using Karatsuba multiplication for feedback calculation
    always @(*) begin
        lfsr_next = {rand_data[6:0], 1'b0} ^ karatsuba_result[7:0];
    end

    // LFSR register update with reset and enable control
    always @(posedge clock) begin
        if (reset)
            rand_data <= 8'h1;
        else if (enable)
            rand_data <= lfsr_next;
    end

endmodule

// 基拉斯基8位乘法器实现
module karatsuba_multiplier_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [15:0] product
);

    wire [3:0] a_high = a[7:4];
    wire [3:0] a_low  = a[3:0];
    wire [3:0] b_high = b[7:4];
    wire [3:0] b_low  = b[3:0];

    wire [7:0] z0;
    wire [7:0] z2;
    wire [7:0] z1;
    wire [7:0] a_sum = a_high ^ a_low;
    wire [7:0] b_sum = b_high ^ b_low;
    wire [7:0] z1_partial;

    // 4位乘法器
    assign z0 = a_low  * b_low;
    assign z2 = a_high * b_high;
    assign z1_partial = a_sum * b_sum;
    assign z1 = z1_partial ^ z2 ^ z0;

    assign product = {z2, 8'b0} ^ {z1, 4'b0} ^ z0;

endmodule