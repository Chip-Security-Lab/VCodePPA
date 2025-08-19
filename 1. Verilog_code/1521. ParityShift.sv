module ParityShift #(parameter DATA_BITS=7) (
    input clk, rst, sin,
    output reg [DATA_BITS:0] sreg // [7:0] for 7+1 parity
);
wire parity = ^sreg[DATA_BITS-1:0];

always @(posedge clk or posedge rst) begin
    if (rst) sreg <= 0;
    else begin
        sreg <= {sreg[DATA_BITS-1:0], sin};
        sreg[DATA_BITS] <= parity;
    end
end
endmodule
