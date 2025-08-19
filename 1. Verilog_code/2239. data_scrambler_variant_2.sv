//SystemVerilog
module data_scrambler #(
    parameter POLY_WIDTH = 16,
    parameter POLYNOMIAL = 16'hA001 // x^16 + x^12 + x^5 + 1
) (
    input wire clk, rst_n,
    input wire data_in,
    input wire scrambled_in,
    input wire bypass_scrambler,
    output reg scrambled_out,
    output reg data_out
);
    // Stage 1: LFSR state and feedback calculation
    reg [POLY_WIDTH-1:0] lfsr_state_stage1;
    wire feedback_stage1;
    reg data_in_stage1;
    reg bypass_stage1;
    
    // Stage 2: Pipeline registers
    reg [POLY_WIDTH-1:0] lfsr_state_stage2;
    reg feedback_stage2;
    reg data_in_stage2;
    reg bypass_stage2;
    
    // Stage 3: Output calculation
    reg valid_pipeline;
    reg valid_pipeline_stage2;
    
    // Pipeline control signals
    reg pipeline_active;
    
    // Descrambler operation pipeline
    reg scrambled_in_stage1, scrambled_in_stage2;
    
    // Calculate feedback based on polynomial
    assign feedback_stage1 = ^(lfsr_state_stage1 & POLYNOMIAL);
    
    // Reset logic
    always @(negedge rst_n) begin
        if (!rst_n) begin
            lfsr_state_stage1 <= {POLY_WIDTH{1'b1}}; // Initialize to all 1s
            lfsr_state_stage2 <= {POLY_WIDTH{1'b1}};
            data_in_stage1 <= 1'b0;
            data_in_stage2 <= 1'b0;
            bypass_stage1 <= 1'b0;
            bypass_stage2 <= 1'b0;
            feedback_stage2 <= 1'b0;
            pipeline_active <= 1'b0;
            valid_pipeline <= 1'b0;
            valid_pipeline_stage2 <= 1'b0;
            scrambled_out <= 1'b0;
            scrambled_in_stage1 <= 1'b0;
            scrambled_in_stage2 <= 1'b0;
            data_out <= 1'b0;
        end
    end
    
    // Stage 1: Input registration
    always @(posedge clk) begin
        if (rst_n) begin
            data_in_stage1 <= data_in;
            bypass_stage1 <= bypass_scrambler;
            pipeline_active <= 1'b1;
        end
    end
    
    // Stage 1: LFSR state update
    always @(posedge clk) begin
        if (rst_n) begin
            // LFSR state update happens in Stage 2
        end
    end
    
    // Stage 2: Pipeline register updates
    always @(posedge clk) begin
        if (rst_n) begin
            lfsr_state_stage2 <= {lfsr_state_stage1[POLY_WIDTH-2:0], feedback_stage1};
            feedback_stage2 <= feedback_stage1;
            data_in_stage2 <= data_in_stage1;
            bypass_stage2 <= bypass_stage1;
            valid_pipeline <= pipeline_active;
        end
    end
    
    // Stage 3: Scrambled output calculation
    always @(posedge clk) begin
        if (rst_n) begin
            valid_pipeline_stage2 <= valid_pipeline;
            if (valid_pipeline) begin
                if (!bypass_stage2) begin
                    // Scramble input data with LFSR output
                    scrambled_out <= data_in_stage2 ^ feedback_stage2;
                end else begin
                    scrambled_out <= data_in_stage2; // Bypass mode
                end
            end
        end
    end
    
    // Descrambler input stage 1
    always @(posedge clk) begin
        if (rst_n) begin
            scrambled_in_stage1 <= scrambled_in;
        end
    end
    
    // Descrambler input stage 2
    always @(posedge clk) begin
        if (rst_n) begin
            scrambled_in_stage2 <= scrambled_in_stage1;
        end
    end
    
    // Final descrambler output stage
    always @(posedge clk) begin
        if (rst_n) begin
            if (valid_pipeline_stage2) begin
                data_out <= scrambled_in_stage2;
            end
        end
    end
endmodule