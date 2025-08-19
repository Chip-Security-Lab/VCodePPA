module int_ctrl_auto_clear #(DW=16)(
    input clk, ack,
    input [DW-1:0] int_src,
    output reg [DW-1:0] int_status
);
always @(posedge clk) begin
    int_status <= (int_status | int_src) & ~(ack ? int_status : {DW{1'b0}});
end
endmodule