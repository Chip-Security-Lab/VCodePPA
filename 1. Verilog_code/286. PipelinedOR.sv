module PipelinedOR(
    input clk,
    input [15:0] stage_a, stage_b,
    output reg [15:0] out
);
    always @(posedge clk) begin
        out <= stage_a | stage_b;  // 单级流水
    end
endmodule
