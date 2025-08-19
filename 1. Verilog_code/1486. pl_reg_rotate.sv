module pl_reg_rotate #(parameter W=8) (
    input clk, load, rotate,
    input [W-1:0] d_in,
    output reg [W-1:0] q
);
always @(posedge clk) begin
    if (load) q <= d_in;
    else if (rotate) q <= {q[W-2:0], q[W-1]};
end
endmodule