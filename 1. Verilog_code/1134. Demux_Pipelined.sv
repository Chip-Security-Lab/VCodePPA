module Demux_Pipelined #(parameter DW=16, STAGES=2) (
    input clk, 
    input [DW-1:0] data_in,
    input [$clog2(STAGES)-1:0] stage_sel,
    output reg [STAGES-1:0][DW-1:0] pipe_out
);
always @(posedge clk) begin
    pipe_out <= 0;
    pipe_out[stage_sel] <= data_in;
end
endmodule