//SystemVerilog
module Mux2D #(parameter W=4, X=2, Y=2) (
    input [W-1:0] matrix [0:X-1][0:Y-1],
    input [$clog2(X)-1:0] x_sel,
    input [$clog2(Y)-1:0] y_sel,
    output reg [W-1:0] element
);
    wire [X*Y-1:0] sel;
    wire [W-1:0] data [0:X*Y-1];
    wire [W-1:0] sum;
    
    genvar i, j;
    generate
        for (i = 0; i < X; i = i + 1) begin : gen_x
            for (j = 0; j < Y; j = j + 1) begin : gen_y
                assign sel[i*Y + j] = (i == x_sel && j == y_sel);
                assign data[i*Y + j] = matrix[i][j];
            end
        end
    endgenerate
    
    // Carry Lookahead Adder implementation
    wire [X*Y:0] carry;
    wire [X*Y-1:0] p, g;
    
    assign carry[0] = 1'b0;
    
    genvar k;
    generate
        for (k = 0; k < X*Y; k = k + 1) begin : gen_adder
            assign p[k] = sel[k] ^ data[k];
            assign g[k] = sel[k] & data[k];
            assign carry[k+1] = g[k] | (p[k] & carry[k]);
        end
    endgenerate
    
    assign sum = p ^ carry[X*Y-1:0];
    
    always @(*) begin
        element = sum;
    end
endmodule