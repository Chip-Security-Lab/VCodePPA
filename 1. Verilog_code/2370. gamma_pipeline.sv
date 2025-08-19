module gamma_pipeline (
    input clk, 
    input [7:0] in,
    output reg [7:0] out
);
reg [7:0] stage1, stage2;
always @(posedge clk) begin
    stage1 <= in * 2;      // Stage 1: Linear scaling
    stage2 <= stage1 - 15; // Stage 2: Offset adjust
    out <= stage2 >> 1;    // Stage 3: Final scaling
end
endmodule
