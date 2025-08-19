//SystemVerilog
module mult_unrolled (
    input [3:0] x, y,
    output reg [7:0] result
);

    reg [7:0] p0, p1, p2, p3;
    wire [7:0] sum1, sum2;
    wire [7:0] carry1, carry2;
    wire [7:0] gen1, gen2;
    wire [7:0] prop1, prop2;

    // Calculate partial products
    always @(*) begin
        p0 = y[0] ? {4'b0, x} : 8'b0;
        p1 = y[1] ? {3'b0, x, 1'b0} : 8'b0;
        p2 = y[2] ? {2'b0, x, 2'b0} : 8'b0;
        p3 = y[3] ? {1'b0, x, 3'b0} : 8'b0;
    end

    // First level carry lookahead
    assign gen1 = p0 & p1;
    assign prop1 = p0 ^ p1;
    assign carry1 = gen1 | (prop1 & 8'b0);
    assign sum1 = prop1 ^ 8'b0;

    // Second level carry lookahead
    assign gen2 = sum1 & p2;
    assign prop2 = sum1 ^ p2;
    assign carry2 = gen2 | (prop2 & carry1);
    assign sum2 = prop2 ^ carry1;

    // Final addition with p3
    always @(*) begin
        result = sum2 + p3;
    end

endmodule