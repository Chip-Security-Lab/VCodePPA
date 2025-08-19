module PipelineArbiter #(parameter STAGES=2) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);
reg [3:0] pipe_req [0:STAGES-1];
integer i;

always @(posedge clk) begin
    if (rst) begin
        for(i=0; i<STAGES; i=i+1)
            pipe_req[i] <= 0;
        grant <= 0;
    end else begin
        pipe_req[0] <= req;
        for(i=1; i<STAGES; i=i+1)
            pipe_req[i] <= pipe_req[i-1];
        grant <= pipe_req[STAGES-1] & (-pipe_req[STAGES-1]); // Priority encoder
    end
end
endmodule