module error_diffusion (
    input clk, 
    input [7:0] in,
    output [3:0] out
);
reg [11:0] err;
wire [11:0] sum = in + err;
assign out = sum[11:8];
always @(posedge clk) begin
    err <= (sum << 4) - (out << 8);
end
endmodule
