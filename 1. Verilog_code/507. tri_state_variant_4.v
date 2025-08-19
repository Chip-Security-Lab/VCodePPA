module tri_state_pipeline #(
    parameter DATA_WIDTH = 1,
    parameter PIPELINE_STAGES = 2
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire enable,
    output wire [DATA_WIDTH-1:0] data_out
);

    // Pipeline registers with packed arrays for better synthesis
    reg [DATA_WIDTH*PIPELINE_STAGES-1:0] data_pipe;
    reg [PIPELINE_STAGES-1:0] enable_pipe;
    
    // Combined pipeline stages with optimized reset logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_pipe <= {DATA_WIDTH*PIPELINE_STAGES{1'b0}};
            enable_pipe <= {PIPELINE_STAGES{1'b0}};
        end else begin
            data_pipe <= {data_pipe[DATA_WIDTH*(PIPELINE_STAGES-1)-1:0], data_in};
            enable_pipe <= {enable_pipe[PIPELINE_STAGES-2:0], enable};
        end
    end

    // Optimized tri-state output with direct indexing
    assign data_out = enable_pipe[PIPELINE_STAGES-1] ? 
                     data_pipe[DATA_WIDTH*PIPELINE_STAGES-1:DATA_WIDTH*(PIPELINE_STAGES-1)] : 
                     {DATA_WIDTH{1'bz}};

endmodule