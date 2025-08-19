//SystemVerilog
module compare_shadow_reg #(
    parameter WIDTH = 8,
    parameter PIPELINE_STAGES = 3  // Pipeline depth
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire update_main,
    input wire update_shadow,
    input wire pipeline_valid_in,  // Input data valid signal
    output wire pipeline_ready_in, // Ready to accept new input
    output reg [WIDTH-1:0] main_data,
    output reg [WIDTH-1:0] shadow_data,
    output reg data_match,
    output reg pipeline_valid_out  // Output valid signal
);
    // Clock buffers to reduce fanout
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // Clock buffer instantiation
    assign clk_buf1 = clk;  // Buffer for stage 1
    assign clk_buf2 = clk;  // Buffer for stage 2
    assign clk_buf3 = clk;  // Buffer for stage 3
    
    // Pipeline stage registers
    reg [WIDTH-1:0] data_in_stage1, data_in_stage2;
    reg update_main_stage1, update_main_stage2;
    reg update_shadow_stage1, update_shadow_stage2;
    reg pipeline_valid_stage1, pipeline_valid_stage2;
    
    // Pre-compute comparison to improve timing
    reg data_match_pre;

    // Pipeline flow control
    assign pipeline_ready_in = 1'b1;  // Always ready in this implementation
    
    // Stage 1: Input Capture
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 0;
            update_main_stage1 <= 0;
            update_shadow_stage1 <= 0;
            pipeline_valid_stage1 <= 0;
        end
        else if (pipeline_ready_in) begin
            data_in_stage1 <= data_in;
            update_main_stage1 <= update_main;
            update_shadow_stage1 <= update_shadow;
            pipeline_valid_stage1 <= pipeline_valid_in;
        end
    end
    
    // Stage 2: Processing
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage2 <= 0;
            update_main_stage2 <= 0;
            update_shadow_stage2 <= 0;
            pipeline_valid_stage2 <= 0;
        end
        else begin
            data_in_stage2 <= data_in_stage1;
            update_main_stage2 <= update_main_stage1;
            update_shadow_stage2 <= update_shadow_stage1;
            pipeline_valid_stage2 <= pipeline_valid_stage1;
        end
    end
    
    // Pre-compute comparison
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n) begin
            data_match_pre <= 0;
        end
        else begin
            data_match_pre <= (main_data == shadow_data);
        end
    end
    
    // Stage 3: Register Updates and Comparison
    always @(posedge clk_buf3 or negedge rst_n) begin
        if (!rst_n) begin
            main_data <= 0;
            shadow_data <= 0;
            data_match <= 0;
            pipeline_valid_out <= 0;
        end
        else begin
            // Main register update
            if (update_main_stage2)
                main_data <= data_in_stage2;
                
            // Shadow register update
            if (update_shadow_stage2)
                shadow_data <= data_in_stage2;
                
            // Use pre-computed comparison result
            data_match <= data_match_pre;
            
            // Output valid signal
            pipeline_valid_out <= pipeline_valid_stage2;
        end
    end
endmodule