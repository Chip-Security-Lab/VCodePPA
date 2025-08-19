//SystemVerilog
module base64_encoder (
    input  wire [23:0] data,
    output reg  [31:0] encoded
);

    // 32位有符号基拉斯基乘法器实现
    wire signed [31:0] mul_a;
    wire signed [31:0] mul_b;
    wire signed [63:0] karatsuba_result;

    assign mul_a = {8'd0, data[23:18]};
    assign mul_b = 32'sd64;

    karatsuba_32x32_to_64 karatsuba_mul_inst (
        .a(mul_a),
        .b(mul_b),
        .p(karatsuba_result)
    );

    // 分解为多个always块
    reg [5:0] encoded_high6;
    reg [5:0] encoded_mid6_1;
    reg [5:0] encoded_mid6_2;
    reg [5:0] encoded_low6;
    reg [7:0] encoded_pad;

    always @* begin
        encoded_high6 = karatsuba_result[11:6];
    end

    always @* begin
        encoded_mid6_1 = data[17:12];
    end

    always @* begin
        encoded_mid6_2 = data[11:6];
    end

    always @* begin
        encoded_low6 = data[5:0];
    end

    always @* begin
        encoded_pad = 8'd0;
    end

    always @* begin
        encoded[31:26] = encoded_high6;
        encoded[25:20] = encoded_mid6_1;
        encoded[19:14] = encoded_mid6_2;
        encoded[13:8]  = encoded_low6;
        encoded[7:0]   = encoded_pad;
    end

endmodule

module karatsuba_32x32_to_64 (
    input  wire signed [31:0] a,
    input  wire signed [31:0] b,
    output wire signed [63:0] p
);
    wire signed [15:0] a_high, a_low, b_high, b_low;
    wire signed [31:0] z0, z2;
    wire signed [32:0] a_sum, b_sum;
    wire signed [33:0] z1_temp;
    wire signed [31:0] z1;
    wire signed [63:0] z2_shifted, z1_shifted, z0_ext;

    assign a_high = a[31:16];
    assign a_low  = a[15:0];
    assign b_high = b[31:16];
    assign b_low  = b[15:0];

    assign z0 = a_low * b_low;
    assign z2 = a_high * b_high;
    assign a_sum = a_low + a_high;
    assign b_sum = b_low + b_high;
    assign z1_temp = a_sum * b_sum;
    assign z1 = z1_temp - z2 - z0;

    assign z2_shifted = {{32{z2[31]}},z2} << 32;
    assign z1_shifted = {{32{z1[31]}},z1} << 16;
    assign z0_ext     = {{32{z0[31]}},z0};

    assign p = z2_shifted + z1_shifted + z0_ext;
endmodule