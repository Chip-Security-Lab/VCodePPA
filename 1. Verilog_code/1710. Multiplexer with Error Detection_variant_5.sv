//SystemVerilog
module error_detect_mux(
    input [7:0] in_a, in_b, in_c, in_d,
    input [1:0] select,
    input valid_a, valid_b, valid_c, valid_d,
    output reg [7:0] out_data,
    output reg error_flag
);
    wire [3:0] valid_vec = {valid_d, valid_c, valid_b, valid_a};
    wire [7:0] mux_in [3:0];
    
    assign mux_in[0] = in_a;
    assign mux_in[1] = in_b;
    assign mux_in[2] = in_c;
    assign mux_in[3] = in_d;
    
    always @(*) begin
        out_data = mux_in[select];
        error_flag = ~valid_vec[select];
    end
endmodule

module karatsuba_multiplier(
    input [7:0] a,
    input [7:0] b,
    output [15:0] result
);
    wire [3:0] a_high = a[7:4];
    wire [3:0] a_low = a[3:0];
    wire [3:0] b_high = b[7:4];
    wire [3:0] b_low = b[3:0];
    
    wire [7:0] z0, z1, z2;
    wire [7:0] a_sum, b_sum;
    wire [15:0] z2_shifted, z1_minus_z2_minus_z0;
    
    carry_lookahead_adder_8bit adder_a(a_high, a_low, 1'b0, a_sum);
    carry_lookahead_adder_8bit adder_b(b_high, b_low, 1'b0, b_sum);
    
    karatsuba_4bit mult_z0(a_low, b_low, z0);
    karatsuba_4bit mult_z1(a_sum, b_sum, z1);
    karatsuba_4bit mult_z2(a_high, b_high, z2);
    
    assign z2_shifted = z2 << 8;
    assign z1_minus_z2_minus_z0 = (z1 - z2 - z0) << 4;
    
    carry_lookahead_adder_16bit final_adder(
        z2_shifted,
        z1_minus_z2_minus_z0 + z0,
        1'b0,
        result
    );
endmodule

module karatsuba_4bit(
    input [3:0] a,
    input [3:0] b,
    output [7:0] result
);
    wire [1:0] a_high = a[3:2];
    wire [1:0] a_low = a[1:0];
    wire [1:0] b_high = b[3:2];
    wire [1:0] b_low = b[1:0];
    
    wire [3:0] z0, z1, z2;
    wire [3:0] a_sum, b_sum;
    wire [7:0] z2_shifted, z1_minus_z2_minus_z0;
    
    carry_lookahead_adder_4bit adder_a(a_high, a_low, 1'b0, a_sum);
    carry_lookahead_adder_4bit adder_b(b_high, b_low, 1'b0, b_sum);
    
    karatsuba_2bit mult_z0(a_low, b_low, z0);
    karatsuba_2bit mult_z1(a_sum, b_sum, z1);
    karatsuba_2bit mult_z2(a_high, b_high, z2);
    
    assign z2_shifted = z2 << 4;
    assign z1_minus_z2_minus_z0 = (z1 - z2 - z0) << 2;
    
    carry_lookahead_adder_8bit final_adder(
        z2_shifted,
        z1_minus_z2_minus_z0 + z0,
        1'b0,
        result
    );
endmodule

module karatsuba_2bit(
    input [1:0] a,
    input [1:0] b,
    output [3:0] result
);
    wire [0:0] a_high = a[1];
    wire [0:0] a_low = a[0];
    wire [0:0] b_high = b[1];
    wire [0:0] b_low = b[0];
    
    wire [1:0] z0, z1, z2;
    wire [1:0] a_sum, b_sum;
    wire [3:0] z2_shifted, z1_minus_z2_minus_z0;
    
    carry_lookahead_adder_2bit adder_a(a_high, a_low, 1'b0, a_sum);
    carry_lookahead_adder_2bit adder_b(b_high, b_low, 1'b0, b_sum);
    
    assign z0 = a_low & b_low;
    assign z1 = a_sum & b_sum;
    assign z2 = a_high & b_high;
    
    assign z2_shifted = z2 << 2;
    assign z1_minus_z2_minus_z0 = (z1 - z2 - z0) << 1;
    
    carry_lookahead_adder_4bit final_adder(
        z2_shifted,
        z1_minus_z2_minus_z0 + z0,
        1'b0,
        result
    );
endmodule

module carry_lookahead_adder_16bit(
    input [15:0] a,
    input [15:0] b,
    input cin,
    output [15:0] sum
);
    wire [15:0] g, p;
    wire [16:0] c;
    
    assign c[0] = cin;
    
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
            assign c[i+1] = g[i] | (p[i] & c[i]);
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
endmodule

module carry_lookahead_adder_8bit(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum
);
    wire [7:0] g, p;
    wire [8:0] c;
    
    assign c[0] = cin;
    
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
            assign c[i+1] = g[i] | (p[i] & c[i]);
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
endmodule

module carry_lookahead_adder_4bit(
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum
);
    wire [3:0] g, p;
    wire [4:0] c;
    
    assign c[0] = cin;
    
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
            assign c[i+1] = g[i] | (p[i] & c[i]);
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
endmodule

module carry_lookahead_adder_2bit(
    input [1:0] a,
    input [1:0] b,
    input cin,
    output [1:0] sum
);
    wire [1:0] g, p;
    wire [2:0] c;
    
    assign c[0] = cin;
    
    genvar i;
    generate
        for (i = 0; i < 2; i = i + 1) begin
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
            assign c[i+1] = g[i] | (p[i] & c[i]);
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
endmodule