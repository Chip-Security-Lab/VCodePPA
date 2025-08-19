//SystemVerilog
module barrel_shifter (
    input signed [7:0] data,
    input [2:0] shift,
    output reg signed [7:0] result
);
    always @(*) begin
        case(shift)
            3'b000: result = data;
            3'b001: result = {data[6:0], 1'b0};
            3'b010: result = {data[5:0], 2'b0};
            3'b011: result = {data[4:0], 3'b0};
            3'b100: result = {data[3:0], 4'b0};
            3'b101: result = {data[2:0], 5'b0};
            3'b110: result = {data[1:0], 6'b0};
            3'b111: result = {data[0], 7'b0};
        endcase
    end
endmodule

module booth_encoder (
    input signed [7:0] a,
    input signed [7:0] b,
    output reg [2:0] booth_code [0:3]
);
    always @(*) booth_code[0] = {b[1:0], 1'b0};
    always @(*) booth_code[1] = b[3:1];
    always @(*) booth_code[2] = b[5:3];
    always @(*) booth_code[3] = b[7:5];
endmodule

module partial_product_generator (
    input signed [7:0] a,
    input [2:0] booth_code,
    output reg signed [8:0] pp
);
    wire signed [7:0] shifted_a;
    barrel_shifter shifter (
        .data(a),
        .shift(booth_code[2:0]),
        .result(shifted_a)
    );

    always @(*) begin
        case(booth_code)
            3'b000: pp = 9'd0;
            3'b001: pp = {shifted_a[7], shifted_a};
            3'b010: pp = {shifted_a[7], shifted_a};
            3'b011: pp = {shifted_a, 1'b0};
            3'b100: pp = -{shifted_a, 1'b0};
            3'b101: pp = -{shifted_a[7], shifted_a};
            3'b110: pp = -{shifted_a[7], shifted_a};
            3'b111: pp = 9'd0;
        endcase
    end
endmodule

module wallace_tree (
    input signed [8:0] pp0,
    input signed [8:0] pp1,
    input signed [8:0] pp2,
    input signed [8:0] pp3,
    output signed [15:0] result
);
    wire signed [10:0] sum1, carry1;
    wire signed [12:0] sum2, carry2;
    wire signed [14:0] sum3, carry3;
    wire signed [8:0] pp1_shifted, pp2_shifted, pp3_shifted;

    barrel_shifter shifter1 (
        .data(pp1[7:0]),
        .shift(3'b010),
        .result(pp1_shifted[7:0])
    );
    assign pp1_shifted[8] = pp1[8];

    barrel_shifter shifter2 (
        .data(pp2[7:0]),
        .shift(3'b100),
        .result(pp2_shifted[7:0])
    );
    assign pp2_shifted[8] = pp2[8];

    barrel_shifter shifter3 (
        .data(pp3[7:0]),
        .shift(3'b110),
        .result(pp3_shifted[7:0])
    );
    assign pp3_shifted[8] = pp3[8];

    assign {carry1, sum1} = pp0 + pp1_shifted;
    assign {carry2, sum2} = sum1 + pp2_shifted;
    assign {carry3, sum3} = sum2 + pp3_shifted;

    assign result = sum3 + (carry3 << 1);
endmodule

module signed_mult (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [15:0] p
);
    wire [2:0] booth_code [0:3];
    wire signed [8:0] pp0, pp1, pp2, pp3;

    booth_encoder encoder (
        .a(a),
        .b(b),
        .booth_code(booth_code)
    );

    partial_product_generator ppg0 (
        .a(a),
        .booth_code(booth_code[0]),
        .pp(pp0)
    );

    partial_product_generator ppg1 (
        .a(a),
        .booth_code(booth_code[1]),
        .pp(pp1)
    );

    partial_product_generator ppg2 (
        .a(a),
        .booth_code(booth_code[2]),
        .pp(pp2)
    );

    partial_product_generator ppg3 (
        .a(a),
        .booth_code(booth_code[3]),
        .pp(pp3)
    );

    wallace_tree tree (
        .pp0(pp0),
        .pp1(pp1),
        .pp2(pp2),
        .pp3(pp3),
        .result(p)
    );
endmodule