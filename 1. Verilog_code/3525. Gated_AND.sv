module Gated_AND(
    input enable,
    input [3:0] vec_a, vec_b,
    output reg [3:0] res
);
    always @(*) begin
        res = enable ? (vec_a & vec_b) : 4'b0000;
    end
endmodule
