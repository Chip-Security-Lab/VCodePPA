module int_ctrl_error_log #(ERR_BITS=4)(
    input clk, rst,
    input [ERR_BITS-1:0] err_in,
    output reg [ERR_BITS-1:0] err_log
);
always @(posedge clk) begin
    if(rst) err_log <= 0;
    else err_log <= err_log | err_in;
end
endmodule