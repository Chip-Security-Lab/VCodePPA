module twos_complement_4bit (
    input [3:0] in,
    output [3:0] out
);
    assign out = ~in + 1'b1;
endmodule

module adder_5bit (
    input [3:0] a,
    input [3:0] b,
    output [4:0] sum
);
    assign sum = {1'b0, a} + {1'b0, b};
endmodule

module overflow_detector_4bit (
    input [3:0] a,
    input [3:0] b,
    input [4:0] sum,
    output overflow
);
    assign overflow = sum[4] ^ a[3] ^ b[3];
endmodule

module subtractor_overflow_4bit (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output overflow
);
    wire [3:0] b_comp;
    wire [4:0] sum;
    
    twos_complement_4bit comp_inst (
        .in(b),
        .out(b_comp)
    );
    
    adder_5bit add_inst (
        .a(a),
        .b(b_comp),
        .sum(sum)
    );
    
    overflow_detector_4bit ovf_inst (
        .a(a),
        .b(b),
        .sum(sum),
        .overflow(overflow)
    );
    
    assign diff = sum[3:0];
endmodule