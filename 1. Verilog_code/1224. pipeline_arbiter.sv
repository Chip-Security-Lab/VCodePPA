module pipeline_arbiter #(WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
reg [WIDTH-1:0] stage1, stage2;
always @(posedge clk) begin
    stage1 <= req_i & (~req_i + 1);      // Stage1: priority select
    stage2 <= stage1;                    // Stage2: pipeline register
    grant_o <= stage2;                   // Stage3: output
end
endmodule
