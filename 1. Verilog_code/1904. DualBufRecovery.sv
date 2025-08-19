module DualBufRecovery #(parameter WIDTH=8) (
    input clk, async_rst,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] buf1, buf2;
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) {buf1, buf2} <= 0;
        else begin
            buf1 <= din;
            buf2 <= buf1;
            dout <= (buf1 & buf2) | (buf1 & din) | (buf2 & din);
        end
    end
endmodule
