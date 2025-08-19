module TimeoutArbiter #(parameter T=10) (
    input clk, rst,
    input req,
    output reg grant
);
reg [7:0] timeout;
always @(posedge clk) begin
    if(rst) {grant, timeout} <= 0;
    else if(timeout == 0) begin
        grant <= req;
        timeout <= (req) ? T : 0;
    end else begin
        timeout <= timeout - 1;
    end
end
endmodule
