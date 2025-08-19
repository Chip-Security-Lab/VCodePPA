module clk_gate_async_rst #(parameter INIT=0) (
    input clk, rst_n, en,
    output reg q
);
always @(posedge clk, negedge rst_n) begin
    if(!rst_n) q <= INIT;
    else if(en) q <= ~q;
end
endmodule