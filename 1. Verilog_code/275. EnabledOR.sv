module EnabledOR(
    input en,
    input [3:0] src1, src2,
    output reg [3:0] res
);
    always @(*) begin
        res = en ? (src1 | src2) : 4'b0000;
    end
endmodule
