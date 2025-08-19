module counter_gray #(parameter BITS=4) (
    input clk, rst_n, en,
    output [BITS-1:0] gray
);
reg [BITS-1:0] bin;
assign gray = bin ^ (bin >> 1);
always @(posedge clk) begin
    if (!rst_n) bin <= 0;
    else if (en) bin <= bin + 1;
end
endmodule