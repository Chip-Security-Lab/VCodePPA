module IVMU_MaskedPriority #(parameter W=16) (
    input clk, rst_n,
    input [W-1:0] int_req,
    input [W-1:0] mask,
    output reg [$clog2(W)-1:0] vec_idx
);
wire [W-1:0] active_req = int_req & ~mask;
always @(posedge clk) begin
    if (!rst_n) vec_idx <= 0;
    else vec_idx <= active_req[0] ? 0 : 
                   active_req[1] ? 1 : vec_idx;
end
endmodule
