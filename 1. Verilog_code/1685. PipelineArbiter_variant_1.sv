//SystemVerilog
module PipelineArbiter #(parameter STAGES=2) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);

reg [3:0] pipe_req [0:STAGES-1];
reg [3:0] priority_mask;
reg [3:0] grant_next;
integer i;

// Reset logic
always @(posedge clk) begin
    if (rst) begin
        for(i=0; i<STAGES; i=i+1)
            pipe_req[i] <= 0;
        priority_mask <= 0;
        grant_next <= 0;
        grant <= 0;
    end
end

// Pipeline stage 0: Input request registration
always @(posedge clk) begin
    if (!rst) begin
        pipe_req[0] <= req;
    end
end

// Pipeline stages 1 to STAGES-1: Request propagation
always @(posedge clk) begin
    if (!rst) begin
        for(i=1; i<STAGES; i=i+1)
            pipe_req[i] <= pipe_req[i-1];
    end
end

// Priority mask generation (split from grant generation)
always @(posedge clk) begin
    if (!rst) begin
        priority_mask <= -pipe_req[STAGES-1];
    end
end

// Grant generation with reduced combinational logic
always @(posedge clk) begin
    if (!rst) begin
        grant_next <= pipe_req[STAGES-1] & priority_mask;
        grant <= grant_next;
    end
end

endmodule