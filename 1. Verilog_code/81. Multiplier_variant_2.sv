//SystemVerilog
// Top-level multiplier module
module Multiplier1(
    input [7:0] a, b,
    output [15:0] result
);

    // Partial product generation
    wire [7:0][15:0] pp;
    PartialProductGenerator pp_gen(
        .a(a),
        .b(b),
        .pp(pp)
    );

    // Partial product accumulation
    wire [15:0] sum;
    PartialProductAccumulator pp_acc(
        .pp(pp),
        .sum(sum)
    );

    // Final result assignment
    assign result = sum;

endmodule

// Partial product generation module
module PartialProductGenerator(
    input [7:0] a,
    input [7:0] b,
    output [7:0][15:0] pp
);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_pp
            assign pp[i] = a & {8{b[i]}};
        end
    endgenerate
endmodule

// Partial product accumulation module
module PartialProductAccumulator(
    input [7:0][15:0] pp,
    output [15:0] sum
);
    wire [15:0] sum1, sum2, sum3, sum4;
    
    // First level of addition
    assign sum1 = pp[0] + (pp[1] << 1);
    assign sum2 = pp[2] + (pp[3] << 1);
    assign sum3 = pp[4] + (pp[5] << 1);
    assign sum4 = pp[6] + (pp[7] << 1);
    
    // Second level of addition
    wire [15:0] sum12, sum34;
    assign sum12 = sum1 + (sum2 << 2);
    assign sum34 = sum3 + (sum4 << 2);
    
    // Final addition
    assign sum = sum12 + (sum34 << 4);
endmodule