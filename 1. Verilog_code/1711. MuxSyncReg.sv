module MuxSyncReg #(parameter W=8, N=4) (
    input clk, rst_n,
    input [N-1:0][W-1:0] data_in,
    input [$clog2(N)-1:0] sel,
    output reg [W-1:0] data_out
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) data_out <= 0;
    else data_out <= data_in[sel];
end
endmodule