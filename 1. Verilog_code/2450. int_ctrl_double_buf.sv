module int_ctrl_double_buf #(WIDTH=8) (
    input clk, swap,
    input [WIDTH-1:0] new_status,
    output [WIDTH-1:0] current_status
);
reg [WIDTH-1:0] buf1, buf2;
always @(posedge clk) begin
    if(swap) buf1 <= buf2;
    buf2 <= new_status;
end
assign current_status = buf1;
endmodule