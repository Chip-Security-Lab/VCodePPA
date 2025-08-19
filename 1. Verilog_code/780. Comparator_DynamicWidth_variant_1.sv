//SystemVerilog
module Comparator_DynamicWidth (
    input         [15:0]  data_x,
    input         [15:0]  data_y,
    input         [3:0]   valid_bits,
    output reg            unequal
);

    // Wallace Tree Multiplier implementation
    wire [15:0] mask;
    MaskGenerator mask_gen (
        .valid_bits(valid_bits),
        .mask(mask)
    );

    // Wallace Tree comparison logic
    wire [15:0] masked_x = data_x & ~mask;
    wire [15:0] masked_y = data_y & ~mask;
    
    // Partial products generation
    wire [15:0] pp [15:0];
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : pp_gen
            assign pp[i] = masked_x[i] ? masked_y : 16'b0;
        end
    endgenerate

    // Wallace Tree reduction
    wire [15:0] sum1, carry1;
    wire [15:0] sum2, carry2;
    wire [15:0] sum3, carry3;
    
    // First reduction stage
    Wallace_Stage1 stage1 (
        .pp(pp),
        .sum(sum1),
        .carry(carry1)
    );

    // Second reduction stage
    Wallace_Stage2 stage2 (
        .sum_in(sum1),
        .carry_in(carry1),
        .sum(sum2),
        .carry(carry2)
    );

    // Final reduction stage
    Wallace_Stage3 stage3 (
        .sum_in(sum2),
        .carry_in(carry2),
        .sum(sum3),
        .carry(carry3)
    );

    // Final comparison
    wire [15:0] final_sum = sum3 + carry3;
    wire comp_result = |final_sum;

    // Output register
    always @(*) begin
        unequal = comp_result;
    end

endmodule

module MaskGenerator (
    input      [3:0]   valid_bits,
    output reg [15:0]  mask
);
    always @(*) begin
        mask = (16'hFFFF << valid_bits);
    end
endmodule

module Wallace_Stage1 (
    input  [15:0] pp [15:0],
    output [15:0] sum,
    output [15:0] carry
);
    // First stage reduction using 3:2 compressors
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : stage1_reduction
            assign {carry[i], sum[i]} = pp[0][i] + pp[1][i] + pp[2][i];
        end
    endgenerate
endmodule

module Wallace_Stage2 (
    input  [15:0] sum_in,
    input  [15:0] carry_in,
    output [15:0] sum,
    output [15:0] carry
);
    // Second stage reduction using 3:2 compressors
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : stage2_reduction
            assign {carry[i], sum[i]} = sum_in[i] + carry_in[i] + sum_in[i+1];
        end
    endgenerate
endmodule

module Wallace_Stage3 (
    input  [15:0] sum_in,
    input  [15:0] carry_in,
    output [15:0] sum,
    output [15:0] carry
);
    // Final stage reduction using 3:2 compressors
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : stage3_reduction
            assign {carry[i], sum[i]} = sum_in[i] + carry_in[i] + carry_in[i+1];
        end
    endgenerate
endmodule