module ICMU_PipelineFSM #(
    parameter STAGES = 3,
    parameter DW = 32
)(
    input clk,
    input rst_async,
    input int_req,
    output reg [DW-1:0] ctx_out,
    output reg ctx_valid
);
    localparam IDLE = 2'b00;
    localparam SAVE_PIPE = 2'b01;
    localparam RESTORE_PIPE = 2'b10;
    
    reg [1:0] pipe_states [0:STAGES-1];
    reg [DW-1:0] pipeline [0:STAGES-1];
    integer i;
    
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            for (i = 0; i < STAGES; i=i+1)
                pipe_states[i] <= IDLE;
            ctx_valid <= 0;
            ctx_out <= 0;
        end else begin
            // Pipeline progression logic
            for (i = STAGES-1; i > 0; i=i-1) begin
                pipe_states[i] <= pipe_states[i-1];
                pipeline[i] <= pipeline[i-1];
            end
            pipe_states[0] <= int_req ? SAVE_PIPE : RESTORE_PIPE;
            pipeline[0] <= {DW{1'b1}}; // Example data (all ones)
            
            ctx_valid <= (pipe_states[STAGES-1] == SAVE_PIPE);
            ctx_out <= pipeline[STAGES-1];
        end
    end
endmodule