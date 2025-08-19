//SystemVerilog
module wallace_multiplier_4bit (
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);

    // Partial products generation
    wire [3:0] pp0 = a & {4{b[0]}};
    wire [3:0] pp1 = a & {4{b[1]}};
    wire [3:0] pp2 = a & {4{b[2]}};
    wire [3:0] pp3 = a & {4{b[3]}};

    // First stage compression
    wire [3:0] s1, c1;
    wire [2:0] s2, c2;
    wire [1:0] s3, c3;

    // First level compression
    assign {c1[0], s1[0]} = pp0[0] + pp1[0];
    assign {c1[1], s1[1]} = pp0[1] + pp1[1] + pp2[0];
    assign {c1[2], s1[2]} = pp0[2] + pp1[2] + pp2[1] + pp3[0];
    assign {c1[3], s1[3]} = pp0[3] + pp1[3] + pp2[2] + pp3[1];

    // Second level compression
    assign {c2[0], s2[0]} = s1[0] + c1[0];
    assign {c2[1], s2[1]} = s1[1] + c1[1] + pp2[0];
    assign {c2[2], s2[2]} = s1[2] + c1[2] + pp2[1] + pp3[0];

    // Third level compression
    assign {c3[0], s3[0]} = s2[0] + c2[0];
    assign {c3[1], s3[1]} = s2[1] + c2[1] + pp3[0];

    // Final addition
    assign product[0] = pp0[0];
    assign product[1] = s1[0];
    assign product[2] = s2[0];
    assign product[3] = s3[0];
    assign product[4] = s3[1] + c3[0];
    assign product[5] = pp3[2] + c3[1];
    assign product[6] = pp3[3];
    assign product[7] = 1'b0;

endmodule

module priority_decoder (
    input [3:0] request,
    output reg [1:0] grant,
    output reg valid
);
    always @(*) begin
        valid = 1'b1;
        if (request[0]) grant = 2'b00;
        else if (request[1]) grant = 2'b01;
        else if (request[2]) grant = 2'b10;
        else if (request[3]) grant = 2'b11;
        else begin
            grant = 2'b00;
            valid = 1'b0;
        end
    end
endmodule