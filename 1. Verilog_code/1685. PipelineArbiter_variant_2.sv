//SystemVerilog
// Priority Encoder Module
module PriorityEncoder #(parameter WIDTH=4) (
    input [WIDTH-1:0] req,
    output reg [WIDTH-1:0] grant
);
    always @(*) begin
        grant = req & (-req); // Priority encoder logic
    end
endmodule

// Pipeline Stage Module
module PipelineStage #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] req_in,
    output reg [WIDTH-1:0] req_out
);
    always @(posedge clk) begin
        if (rst) begin
            req_out <= 0;
        end else begin
            req_out <= req_in;
        end
    end
endmodule

// Top Level Pipeline Arbiter
module PipelineArbiter #(parameter STAGES=4, WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] req,
    output [WIDTH-1:0] grant
);
    wire [WIDTH-1:0] stage_req [0:STAGES-1];
    wire [WIDTH-1:0] stage_grant;
    
    // Input stage
    PipelineStage #(.WIDTH(WIDTH)) input_stage (
        .clk(clk),
        .rst(rst),
        .req_in(req),
        .req_out(stage_req[0])
    );
    
    // Pipeline stages
    genvar i;
    generate
        for (i=1; i<STAGES; i=i+1) begin : pipeline_stages
            PipelineStage #(.WIDTH(WIDTH)) stage (
                .clk(clk),
                .rst(rst),
                .req_in(stage_req[i-1]),
                .req_out(stage_req[i])
            );
        end
    endgenerate
    
    // Priority encoder
    PriorityEncoder #(.WIDTH(WIDTH)) encoder (
        .req(stage_req[STAGES-1]),
        .grant(grant)
    );
endmodule