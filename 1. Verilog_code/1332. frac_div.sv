module frac_div #(parameter M=3, N=7) (
    input clk, rst,
    output reg out
);
reg [7:0] acc;
always @(posedge clk) begin
    if(rst) {acc,out} <= 0;
    else begin
        acc <= acc >= N ? acc + M - N : acc + M;
        out <= acc < N ? 1'b0 : 1'b1;
    end
end
endmodule
