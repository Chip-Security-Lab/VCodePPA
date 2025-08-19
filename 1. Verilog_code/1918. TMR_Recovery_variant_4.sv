//SystemVerilog
module TMR_Recovery #(parameter WIDTH=8) (
    input  [WIDTH-1:0] ch0, ch1, ch2,
    output [WIDTH-1:0] data_out
);
    wire [WIDTH-1:0] majority_vote;
    wire [WIDTH-1:0] lut_sub_result0;
    wire [WIDTH-1:0] lut_sub_result1;
    wire [WIDTH-1:0] lut_sub_result2;

    // Instantiate LUT-based subtractor for ch0 - ch1
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : LUT_SUB0
            LUT8_Subtractor sub_lut0 (
                .a(ch0[i]),
                .b(ch1[i]),
                .diff(lut_sub_result0[i])
            );
        end
    endgenerate

    // Instantiate LUT-based subtractor for ch1 - ch2
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : LUT_SUB1
            LUT8_Subtractor sub_lut1 (
                .a(ch1[i]),
                .b(ch2[i]),
                .diff(lut_sub_result1[i])
            );
        end
    endgenerate

    // Instantiate LUT-based subtractor for ch0 - ch2
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : LUT_SUB2
            LUT8_Subtractor sub_lut2 (
                .a(ch0[i]),
                .b(ch2[i]),
                .diff(lut_sub_result2[i])
            );
        end
    endgenerate

    // Use LUT-based subtractor results to reconstruct the majority logic
    assign majority_vote = (~lut_sub_result0 & ~lut_sub_result1) |
                           (~lut_sub_result1 & ~lut_sub_result2) |
                           (~lut_sub_result0 & ~lut_sub_result2);

    assign data_out = majority_vote;

endmodule

// 1-bit LUT-based subtractor (for 8-bit bus, instantiate 8 times)
module LUT8_Subtractor (
    input  a,
    input  b,
    output diff
);
    // 1-bit subtractor result: diff = a ^ b
    // Use a 2-to-1 LUT for the subtraction
    reg [1:0] lut_table;
    always @(*) begin
        lut_table[0] = 1'b0; // a=0, b=0: diff=0
        lut_table[1] = 1'b1; // a=1, b=0: diff=1
    end
    assign diff = a ^ b;
endmodule