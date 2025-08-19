//SystemVerilog
module HanCarlsonAdder #(parameter WIDTH = 8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);

    wire [WIDTH:0] p, g;
    wire [WIDTH:0] c;
    
    // Generate and Propagate
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pg
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
    endgenerate
    
    // Carry computation
    assign c[0] = cin;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_carry
            assign c[i+1] = g[i] | (p[i] & c[i]);
        end
    endgenerate
    
    // Sum computation
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
    
    assign cout = c[WIDTH];
endmodule

module Mux2D #(parameter W=4, X=2, Y=2) (
    input [W-1:0] matrix [0:X-1][0:Y-1],
    input [$clog2(X)-1:0] x_sel,
    input [$clog2(Y)-1:0] y_sel,
    output reg [W-1:0] element
);
    integer i, j;
    always @(*) begin
        element = 0;
        i = 0;
        while (i < X) begin
            j = 0;
            while (j < Y) begin
                if (i == x_sel && j == y_sel)
                    element = matrix[i][j];
                j = j + 1;
            end
            i = i + 1;
        end
    end
endmodule