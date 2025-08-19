//SystemVerilog
module IVMU_MaskedPriority #(parameter W=16) (
    input clk, rst_n,
    input [W-1:0] int_req,
    input [W-1:0] mask,
    output reg [$clog2(W)-1:0] vec_idx
);

wire [W-1:0] active_req = int_req & ~mask;

always @(posedge clk) begin
    if (!rst_n) begin
        vec_idx <= 0;
    end else if (active_req[0]) begin
        // This condition corresponds to the first branch of the original nested structure
        vec_idx <= 0;
    end else if (active_req[1]) begin
        // This condition corresponds to the second branch of the original nested structure,
        // implicitly checked only if active_req[0] is false
        vec_idx <= 1;
    end
    // If none of the above conditions are met (not reset, active_req[0] is 0, active_req[1] is 0),
    // the 'vec_idx' register retains its previous value, preserving the original behavior.
end

endmodule