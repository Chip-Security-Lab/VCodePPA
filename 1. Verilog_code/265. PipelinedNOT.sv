module PipelinedNOT(
    input clk,
    input [31:0] stage_in,
    output reg [31:0] stage_out
);
    always @(posedge clk) begin
        stage_out <= ~stage_in;  // 流水线寄存器
    end
endmodule

