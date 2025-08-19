module int_ctrl_delay #(DLY=2)(
    input clk, int_in,
    output int_out
);
reg [DLY-1:0] delay_chain;
always @(posedge clk) delay_chain <= {delay_chain[DLY-2:0], int_in};
assign int_out = delay_chain[DLY-1];
endmodule