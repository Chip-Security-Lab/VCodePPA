module BiDirShift #(parameter BITS=8) (
    input clk, rst, dir, s_in,
    output reg [BITS-1:0] q
);
always @(posedge clk) begin
    if (rst) q <= 0;
    else q <= dir ? {q[BITS-2:0], s_in} : {s_in, q[BITS-1:1]};
end
endmodule
