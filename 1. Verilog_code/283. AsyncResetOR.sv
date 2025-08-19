module AsyncResetOR(
    input rst_n,
    input [3:0] d1, d2,
    output reg [3:0] q
);
    always @(*) begin
        q = rst_n ? (d1 | d2) : 4'b1111;
    end
endmodule
