module GatedClockShift #(parameter BITS=8) (
    input gclk,  // 门控时钟
    input en, s_in,
    output reg [BITS-1:0] q
);
always @(posedge gclk) begin
    if (en) q <= {q[BITS-2:0], s_in};
end
endmodule
