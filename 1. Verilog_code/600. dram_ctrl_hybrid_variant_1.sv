//SystemVerilog
module dram_ctrl_hybrid #(
    parameter MODE = 0, // 0=SDR, 1=DDR
    parameter PIPELINE_STAGES = 4
)(
    input clk,
    input ddr_clk,
    input rst_n,
    output reg [15:0] dq_out,
    output reg valid_out
);

    // Pipeline registers
    reg [15:0] data_pipe [PIPELINE_STAGES-1:0];
    reg valid_pipe [PIPELINE_STAGES-1:0];
    
    // Stage 1: Data generation
    reg [15:0] stage1_data;
    reg stage1_valid;
    
    // Stage 2: Data processing
    reg [15:0] stage2_data;
    reg stage2_valid;

    // Stage 3: Data alignment
    reg [15:0] stage3_data;
    reg stage3_valid;

    // Stage 4: Output preparation
    reg [15:0] stage4_data;
    reg stage4_valid;

    // Stage 1 logic
    always @(*) begin
        if(MODE == 1) begin
            stage1_data = ddr_clk ? 16'hF0F0 : 16'h0F0F;
        end else begin
            stage1_data = 16'h1234;
        end
    end

    // Pipeline control
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            stage1_valid <= 1'b0;
            stage2_valid <= 1'b0;
            stage3_valid <= 1'b0;
            stage4_valid <= 1'b0;
            valid_out <= 1'b0;
            for(int i=0; i<PIPELINE_STAGES; i++) begin
                data_pipe[i] <= 16'h0;
                valid_pipe[i] <= 1'b0;
            end
        end else begin
            // Stage 1 register
            data_pipe[0] <= stage1_data;
            valid_pipe[0] <= 1'b1;
            
            // Pipeline stages
            for(int i=1; i<PIPELINE_STAGES; i++) begin
                data_pipe[i] <= data_pipe[i-1];
                valid_pipe[i] <= valid_pipe[i-1];
            end
            
            // Output stage
            dq_out <= data_pipe[PIPELINE_STAGES-1];
            valid_out <= valid_pipe[PIPELINE_STAGES-1];
        end
    end

endmodule