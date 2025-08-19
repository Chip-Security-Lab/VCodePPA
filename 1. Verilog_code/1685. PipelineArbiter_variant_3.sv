//SystemVerilog
module PipelineArbiter #(
    parameter STAGES = 2,
    parameter REQ_WIDTH = 4
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [REQ_WIDTH-1:0]     req,
    output reg  [REQ_WIDTH-1:0]     grant
);

    // Pipeline stage registers
    reg [REQ_WIDTH-1:0] req_pipe [0:STAGES-1];
    reg [REQ_WIDTH-1:0] priority_req;
    reg [REQ_WIDTH-1:0] grant_next;
    
    // Priority encoder logic
    wire [REQ_WIDTH-1:0] priority_mask;
    wire [REQ_WIDTH-1:0] grant_mask;
    
    // Priority encoding
    assign priority_mask = priority_req & (-priority_req);
    assign grant_mask = priority_mask;
    
    // Pipeline stages
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline stages
            for (int i = 0; i < STAGES; i++) begin
                req_pipe[i] <= '0;
            end
            priority_req <= '0;
            grant <= '0;
            grant_next <= '0;
        end else begin
            // First pipeline stage - capture input requests
            req_pipe[0] <= req;
            
            // Middle pipeline stages - propagate requests
            for (int i = 1; i < STAGES; i++) begin
                req_pipe[i] <= req_pipe[i-1];
            end
            
            // Final pipeline stage - priority encoding
            priority_req <= req_pipe[STAGES-1];
            grant_next <= grant_mask;
            grant <= grant_next;
        end
    end

endmodule