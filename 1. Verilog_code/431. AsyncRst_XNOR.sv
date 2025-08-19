module AsyncRst_XNOR(
    input rst_n,
    input [3:0] src_a, src_b,
    output reg [3:0] q
);
    always @(*) begin
        q = rst_n ? ~(src_a ^ src_b) : 4'b0000;
    end
endmodule
