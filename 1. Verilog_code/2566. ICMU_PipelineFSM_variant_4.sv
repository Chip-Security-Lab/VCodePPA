//SystemVerilog
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
    
    // Optimized counter using parallel prefix approach
    reg [1:0] stage_counter;
    wire [1:0] next_counter = stage_counter - 1'b1;
    
    // Optimized state transition logic
    wire [1:0] next_state = int_req ? SAVE_PIPE : RESTORE_PIPE;
    wire [DW-1:0] next_data = {DW{1'b1}};
    
    // Optimized output logic
    wire output_valid = (pipe_states[STAGES-1] == SAVE_PIPE);
    wire [DW-1:0] output_data = pipeline[STAGES-1];
    
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            for (integer i = 0; i < STAGES; i=i+1) begin
                pipe_states[i] <= IDLE;
                pipeline[i] <= {DW{1'b0}};
            end
            ctx_valid <= 1'b0;
            ctx_out <= {DW{1'b0}};
            stage_counter <= 2'b00;
        end else begin
            // Optimized pipeline progression using parallel shift
            for (integer i = STAGES-1; i > 0; i=i-1) begin
                pipe_states[i] <= pipe_states[i-1];
                pipeline[i] <= pipeline[i-1];
            end
            
            // Optimized state and data updates
            pipe_states[0] <= next_state;
            pipeline[0] <= next_data;
            stage_counter <= next_counter;
            
            // Optimized output updates
            ctx_valid <= output_valid;
            ctx_out <= output_data;
        end
    end
endmodule