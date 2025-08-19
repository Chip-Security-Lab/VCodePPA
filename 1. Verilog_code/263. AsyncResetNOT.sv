module AsyncResetNOT(
    input rst_n,
    input [3:0] d,
    output reg [3:0] q
);
    always @(*) begin
        q = rst_n ? ~d : 4'b0000;  // 复位强制输出低
    end
endmodule

