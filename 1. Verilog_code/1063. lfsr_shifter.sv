module lfsr_shifter #(parameter WIDTH=8, TAPS=8'h8E) (
    input clk, rst,
    output reg [WIDTH-1:0] lfsr
);
always @(posedge clk or posedge rst) begin
    if (rst) lfsr <= 8'hFF;
    else lfsr <= {lfsr[6:0], ^(lfsr & TAPS)};
end
endmodule
