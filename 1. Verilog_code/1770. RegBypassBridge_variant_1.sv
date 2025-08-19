//SystemVerilog
module RegBypassBridge #(
    parameter WIDTH = 32,
    parameter PIPELINE_STAGES = 4  // 增加默认流水线级数
)(
    input clk, rst_n,
    input [WIDTH-1:0] reg_in,
    output reg [WIDTH-1:0] reg_out,
    input bypass_en,
    output reg valid_out
);

    // Pipeline registers
    reg [WIDTH-1:0] pipeline_reg [PIPELINE_STAGES-1:0];
    reg [PIPELINE_STAGES-1:0] valid_pipeline;
    
    // Input registration stage
    reg [WIDTH-1:0] reg_in_stage0;
    reg bypass_en_stage0;
    
    // Register input signals for better timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_in_stage0 <= {WIDTH{1'b0}};
            bypass_en_stage0 <= 1'b0;
        end else begin
            reg_in_stage0 <= reg_in;
            bypass_en_stage0 <= bypass_en;
        end
    end
    
    // Stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_reg[0] <= {WIDTH{1'b0}};
            valid_pipeline[0] <= 1'b0;
        end else begin
            if (bypass_en_stage0) begin
                pipeline_reg[0] <= reg_in_stage0;
                valid_pipeline[0] <= 1'b1;
            end else begin
                pipeline_reg[0] <= pipeline_reg[0];
                valid_pipeline[0] <= valid_pipeline[0];
            end
        end
    end

    // Middle stages with sub-stages for load balancing
    genvar i;
    generate
        for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin : gen_pipeline
            // Split each pipeline stage into two sub-stages for better timing
            reg [WIDTH-1:0] pipeline_reg_half [1:0];
            reg [1:0] valid_pipeline_half;
            
            // First half of the stage
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    pipeline_reg_half[0] <= {WIDTH{1'b0}};
                    valid_pipeline_half[0] <= 1'b0;
                end else begin
                    pipeline_reg_half[0] <= pipeline_reg[i-1];
                    valid_pipeline_half[0] <= valid_pipeline[i-1];
                end
            end
            
            // Second half of the stage
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    pipeline_reg[i] <= {WIDTH{1'b0}};
                    valid_pipeline[i] <= 1'b0;
                end else begin
                    pipeline_reg[i] <= pipeline_reg_half[0];
                    valid_pipeline[i] <= valid_pipeline_half[0];
                end
            end
        end
    endgenerate

    // Pre-output stage
    reg [WIDTH-1:0] pre_output_reg;
    reg pre_output_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pre_output_reg <= {WIDTH{1'b0}};
            pre_output_valid <= 1'b0;
        end else begin
            pre_output_reg <= pipeline_reg[PIPELINE_STAGES-1];
            pre_output_valid <= valid_pipeline[PIPELINE_STAGES-1];
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_out <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            reg_out <= pre_output_reg;
            valid_out <= pre_output_valid;
        end
    end

endmodule