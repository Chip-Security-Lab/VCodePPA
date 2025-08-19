module XORChain (
    input clk, rst_n,
    input [7:0] din,
    output reg [7:0] dout
);
reg [7:0] prev;
always @(posedge clk) begin
    if(!rst_n) prev <= 0;
    else begin
        dout <= prev ^ din;
        prev <= din;
    end
end
endmodule
