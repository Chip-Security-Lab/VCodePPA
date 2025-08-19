module int_ctrl_timeout #(TIMEOUT=8) (
    input clk, int_pending,
    output reg timeout
);
reg [3:0] counter;
always @(posedge clk) begin
    if(int_pending) counter <= (counter == TIMEOUT) ? 0 : counter + 1;
    timeout <= (counter == TIMEOUT);
end
endmodule