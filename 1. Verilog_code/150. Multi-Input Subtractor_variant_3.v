module karatsuba_mult_2bit (
    input wire [1:0] a,
    input wire [1:0] b,
    output wire [3:0] res
);
    wire [1:0] a_high = a[1];
    wire [1:0] a_low = a[0];
    wire [1:0] b_high = b[1];
    wire [1:0] b_low = b[0];
    
    wire [1:0] z0 = a_low * b_low;
    wire [1:0] z2 = a_high * b_high;
    wire [1:0] z1 = (a_high + a_low) * (b_high + b_low) - z0 - z2;
    
    assign res = {z2, 2'b0} + {z1, 1'b0} + z0;
endmodule

module karatsuba_mult_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [7:0] res
);
    wire [1:0] a_high = a[3:2];
    wire [1:0] a_low = a[1:0];
    wire [1:0] b_high = b[3:2];
    wire [1:0] b_low = b[1:0];
    
    wire [3:0] z0, z2;
    karatsuba_mult_2bit mult_low (a_low, b_low, z0);
    karatsuba_mult_2bit mult_high (a_high, b_high, z2);
    
    wire [1:0] sum_a = a_high + a_low;
    wire [1:0] sum_b = b_high + b_low;
    wire [3:0] z1;
    karatsuba_mult_2bit mult_mid (sum_a, sum_b, z1);
    
    wire [7:0] z1_final = z1 - z0 - z2;
    
    assign res = {z2, 4'b0} + {z1_final, 2'b0} + z0;
endmodule

module subtractor_multi_input (
    input wire [3:0] a,
    input wire [3:0] b,
    input wire [3:0] c,
    input wire [3:0] d,
    output reg [3:0] res
);

wire [7:0] mult_ab, mult_ac, mult_ad;
wire [7:0] mult_bc, mult_bd;
wire [7:0] mult_cd;

karatsuba_mult_4bit mult_ab_inst (a, b, mult_ab);
karatsuba_mult_4bit mult_ac_inst (a, c, mult_ac);
karatsuba_mult_4bit mult_ad_inst (a, d, mult_ad);
karatsuba_mult_4bit mult_bc_inst (b, c, mult_bc);
karatsuba_mult_4bit mult_bd_inst (b, d, mult_bd);
karatsuba_mult_4bit mult_cd_inst (c, d, mult_cd);

wire [7:0] sum_ab = mult_ab[3:0];
wire [7:0] sum_abc = sum_ab + mult_ac[3:0];
wire [7:0] sum_abc_d = sum_abc - mult_ad[3:0];

always @(*) begin
    res = sum_abc_d[3:0];
end

endmodule