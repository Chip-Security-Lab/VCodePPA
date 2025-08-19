module DeltaEncoder (
    input clk, rst_n,
    input [15:0] din,
    output reg [15:0] dout
);
reg [15:0] prev;
always @(posedge clk) begin
    if (!rst_n) prev <= 0;
    else begin
        dout <= din - prev;
        prev <= din;
    end
end
endmodule
