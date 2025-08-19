module HybridOR(
    input [1:0] sel,
    input [7:0] data,
    output [7:0] result
);
    assign result = data | (8'hFF << (sel * 2));
endmodule
