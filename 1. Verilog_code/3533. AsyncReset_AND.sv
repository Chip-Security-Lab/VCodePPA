module AsyncReset_AND(
    input rst_n,
    input [3:0] src1, src2,
    output reg [3:0] q
);
    always @(*) begin
        q = rst_n ? (src1 & src2) : 4'b0000;
    end
endmodule
