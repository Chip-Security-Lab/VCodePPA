module int_ctrl_dist_arb #(N=4)(
    input [N-1:0] req,
    output [N-1:0] grant
);
assign grant = req & ~(req-1);  // Round-robin arbitration
endmodule