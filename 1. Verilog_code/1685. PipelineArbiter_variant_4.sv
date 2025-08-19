//SystemVerilog
module PipelineArbiter #(parameter STAGES=2) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);

reg [3:0] pipe_req [0:STAGES-1];
reg [3:0] priority_mask;
reg [3:0] next_grant;

// Reset logic
always @(posedge clk) begin
    if (rst) begin
        grant <= 0;
    end
end

// Reset pipeline registers
always @(posedge clk) begin
    if (rst) begin
        for(int i=0; i<STAGES; i=i+1)
            pipe_req[i] <= 0;
    end
end

// Input stage pipeline
always @(posedge clk) begin
    if (!rst) begin
        pipe_req[0] <= req;
    end
end

// Pipeline stages
always @(posedge clk) begin
    if (!rst) begin
        for(int i=1; i<STAGES; i=i+1)
            pipe_req[i] <= pipe_req[i-1];
    end
end

// Priority mask generation
always @(posedge clk) begin
    if (!rst) begin
        priority_mask <= ~pipe_req[STAGES-1] + 1;
    end
end

// Grant generation
always @(posedge clk) begin
    if (!rst) begin
        grant <= pipe_req[STAGES-1] & priority_mask;
    end
end

endmodule