//SystemVerilog
module ICMU_PipelineFSM #(
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
    
    reg [1:0] pipe_state;
    reg [DW-1:0] pipeline_data;
    
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            pipe_state <= IDLE;
            ctx_valid <= 0;
            ctx_out <= 0;
        end else begin
            // Pipeline progression logic using if-else instead of conditional operator
            if (int_req) begin
                pipe_state <= SAVE_PIPE;
            end else begin
                pipe_state <= RESTORE_PIPE;
            end
            
            pipeline_data <= {DW{1'b1}}; // Example data (all ones)
            
            // Context validation logic using if-else
            if (pipe_state == SAVE_PIPE) begin
                ctx_valid <= 1'b1;
            end else begin
                ctx_valid <= 1'b0;
            end
            
            ctx_out <= pipeline_data;
        end
    end
endmodule