module IVMU_HybridArb #(parameter MODE=0) (
    input clk,
    input [3:0] req,
    output reg [1:0] grant
);
always @(posedge clk) begin
    grant <= MODE ? 
           (req[0] ? 0 : req[1] ? 1 : 2) :  // Fixed
           (grant == 3) ? 0 : grant + 1;    // Round-robin
end
endmodule
