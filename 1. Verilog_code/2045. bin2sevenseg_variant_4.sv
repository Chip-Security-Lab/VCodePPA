//SystemVerilog
module bin2sevenseg_mult_wallace (
    input wire [3:0] bin_in_a,
    input wire [3:0] bin_in_b,
    output reg [6:0] seg_out_n // active low {a,b,c,d,e,f,g}
);
    wire [6:0] mult_result;

    wallace_7bit_multiplier u_wallace_mult (
        .a({3'b000, bin_in_a}), // sign-extend to 7 bits
        .b({3'b000, bin_in_b}), // sign-extend to 7 bits
        .product(mult_result)
    );

    always @(*) begin
        case (mult_result[3:0])
            4'h0: seg_out_n = 7'b0000001;  // 0
            4'h1: seg_out_n = 7'b1001111;  // 1
            4'h2: seg_out_n = 7'b0010010;  // 2
            4'h3: seg_out_n = 7'b0000110;  // 3
            4'h4: seg_out_n = 7'b1001100;  // 4
            default: seg_out_n = 7'b1111111;  // blank
        endcase
    end
endmodule

module wallace_7bit_multiplier (
    input wire [6:0] a,
    input wire [6:0] b,
    output wire [13:0] product
);
    wire [6:0] pp [6:0];

    // Generate Partial Products
    genvar i;
    generate
        for (i = 0; i < 7; i = i + 1) begin : gen_pp
            assign pp[i] = b[i] ? a : 7'b0;
        end
    endgenerate

    // Stage 1: First layer of adders
    wire [7:0] s1_0, s1_1, s1_2;
    wire [7:0] c1_0, c1_1, c1_2;

    wallace_full_adder_7 fa1_0 (
        .in1({1'b0, pp[0]}),
        .in2({pp[1], 1'b0}),
        .in3({pp[2], 2'b00}),
        .sum(s1_0),
        .carry(c1_0)
    );
    wallace_full_adder_7 fa1_1 (
        .in1({pp[3], 3'b000}),
        .in2({pp[4], 4'b0000}),
        .in3({pp[5], 5'b00000}),
        .sum(s1_1),
        .carry(c1_1)
    );
    assign s1_2 = {pp[6], 6'b000000};
    assign c1_2 = 8'b0;

    // Stage 2: Second layer of adders
    wire [8:0] s2_0, c2_0;
    wallace_full_adder_8 fa2_0 (
        .in1({1'b0, s1_0}),
        .in2({1'b0, s1_1}),
        .in3({1'b0, s1_2}),
        .sum(s2_0),
        .carry(c2_0)
    );

    wire [8:0] s2_1, c2_1;
    wallace_full_adder_8 fa2_1 (
        .in1({c1_0, 1'b0}),
        .in2({c1_1, 1'b0}),
        .in3({c1_2, 1'b0}),
        .sum(s2_1),
        .carry(c2_1)
    );

    // Stage 3: Final adder (carry-propagate adder)
    assign product = s2_0 + s2_1 + (c2_0 << 1) + (c2_1 << 1);

endmodule

module wallace_full_adder_7 (
    input  wire [7:0] in1,
    input  wire [7:0] in2,
    input  wire [7:0] in3,
    output wire [7:0] sum,
    output wire [7:0] carry
);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : fa
            assign {carry[i], sum[i]} = in1[i] + in2[i] + in3[i];
        end
    endgenerate
endmodule

module wallace_full_adder_8 (
    input  wire [8:0] in1,
    input  wire [8:0] in2,
    input  wire [8:0] in3,
    output wire [8:0] sum,
    output wire [8:0] carry
);
    genvar i;
    generate
        for (i = 0; i < 9; i = i + 1) begin : fa
            assign {carry[i], sum[i]} = in1[i] + in2[i] + in3[i];
        end
    endgenerate
endmodule