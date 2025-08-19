module int_ctrl_polling #(CNT_W=3)(
    input clk, enable,
    input [2**CNT_W-1:0] int_src,
    output reg int_valid,
    output [CNT_W-1:0] int_id
);
reg [CNT_W-1:0] poll_counter;
always @(posedge clk) begin
    if(enable) poll_counter <= poll_counter + 1;
    int_valid <= int_src[poll_counter];
end
assign int_id = poll_counter;
endmodule