module twos_complement_8bit (
    input signed [7:0] in,
    output signed [7:0] out
);
    assign out = -in;
endmodule

module adder_9bit (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [8:0] sum
);
    assign sum = $signed({a[7], a}) + $signed({b[7], b});
endmodule

module overflow_detector_8bit (
    input signed [8:0] sum,
    output overflow
);
    assign overflow = (sum[8] != sum[7]);
endmodule

module subtractor_signed_overflow_8bit (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] diff,
    output overflow
);
    wire signed [8:0] sum;
    
    assign sum = $signed({a[7], a}) - $signed({b[7], b});
    assign diff = sum[7:0];
    assign overflow = (sum[8] != sum[7]);
endmodule