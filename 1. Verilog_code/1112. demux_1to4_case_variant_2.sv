//SystemVerilog
module demux_1to4_case (
    input wire din,                  // Data input
    input wire [1:0] select,         // 2-bit selection control
    input wire [3:0] multiplier_a,   // 4-bit signed multiplicand input
    input wire [3:0] multiplier_b,   // 4-bit signed multiplier input
    output reg [3:0] dout,           // 4-bit output bus
    output wire [7:0] mul_result     // 8-bit signed multiplication result
);

    wire [7:0] bw_mul_out;

    baugh_wooley_4bit_multiplier u_baugh_wooley_4bit_multiplier (
        .a(multiplier_a),
        .b(multiplier_b),
        .product(bw_mul_out)
    );

    assign mul_result = bw_mul_out;

    always @(*) begin
        dout = 4'b0000;              // Default all outputs to zero
        case(select)
            2'b00: dout[0] = din;
            2'b01: dout[1] = din;
            2'b10: dout[2] = din;
            2'b11: dout[3] = din;
        endcase
    end
endmodule

module baugh_wooley_4bit_multiplier (
    input  wire [3:0] a,             // 4-bit signed multiplicand
    input  wire [3:0] b,             // 4-bit signed multiplier
    output wire [7:0] product        // 8-bit signed product
);

    // Partial products
    wire pp00 = a[0] & b[0];
    wire pp01 = a[0] & b[1];
    wire pp02 = a[0] & b[2];
    wire pp03 = a[0] & b[3];

    wire pp10 = a[1] & b[0];
    wire pp11 = a[1] & b[1];
    wire pp12 = a[1] & b[2];
    wire pp13 = a[1] & b[3];

    wire pp20 = a[2] & b[0];
    wire pp21 = a[2] & b[1];
    wire pp22 = a[2] & b[2];
    wire pp23 = a[2] & b[3];

    wire pp30 = a[3] & b[0];
    wire pp31 = a[3] & b[1];
    wire pp32 = a[3] & b[2];
    wire pp33 = a[3] & b[3];

    // Baugh-Wooley corrections for sign bits
    // a[3] and b[3] are sign bits

    // Correction terms
    wire c1 = ~(a[3] & b[0]);
    wire c2 = ~(a[3] & b[1]);
    wire c3 = ~(a[3] & b[2]);
    wire c4 = ~(a[0] & b[3]);
    wire c5 = ~(a[1] & b[3]);
    wire c6 = ~(a[2] & b[3]);
    wire c7 = a[3] & b[3];

    // Stage 1: column 0
    wire s0 = pp00;

    // Stage 2: column 1
    wire [1:0] col1_sum;
    assign col1_sum = pp01 + pp10;

    // Stage 3: column 2
    wire [2:0] col2_sum;
    assign col2_sum = {1'b0, pp02} + {1'b0, pp11} + {1'b0, pp20};

    // Stage 4: column 3
    wire [2:0] col3_sum;
    assign col3_sum = {1'b0, pp03} + {1'b0, pp12} + {1'b0, pp21} + {1'b0, pp30}
                    + {2'b0, c1} + {2'b0, c4};

    // Stage 5: column 4
    wire [2:0] col4_sum;
    assign col4_sum = {1'b0, pp13} + {1'b0, pp22} + {1'b0, pp31}
                    + {2'b0, c2} + {2'b0, c5};

    // Stage 6: column 5
    wire [1:0] col5_sum;
    assign col5_sum = pp23 + pp32 + c3 + c6;

    // Stage 7: column 6
    wire s6 = pp33 + c7;

    // Carry-save addition and final sum
    wire [7:0] sum;
    wire [7:0] carry;

    // Bit 0
    assign sum[0] = s0;
    assign carry[0] = 1'b0;

    // Bit 1
    assign sum[1] = col1_sum[0];
    assign carry[1] = col1_sum[1];

    // Bit 2
    assign sum[2] = col2_sum[0];
    assign carry[2] = col2_sum[1];

    // Bit 3
    assign sum[3] = col3_sum[0];
    assign carry[3] = col3_sum[1];

    // Bit 4
    assign sum[4] = col4_sum[0];
    assign carry[4] = col4_sum[1];

    // Bit 5
    assign sum[5] = col5_sum[0];
    assign carry[5] = col5_sum[1];

    // Bit 6
    assign sum[6] = s6;
    assign carry[6] = 1'b0;

    // Bit 7
    assign sum[7] = 1'b0;
    assign carry[7] = 1'b0;

    // Final addition
    assign product = sum + (carry << 1);

endmodule