module PipelineMatcher #(parameter WIDTH=8) (
    input clk, 
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] pattern,
    output reg match
);
reg [WIDTH-1:0] pipe_stage;
always @(posedge clk) begin
    pipe_stage <= data_in;
    match <= (pipe_stage == pattern);
end
endmodule
