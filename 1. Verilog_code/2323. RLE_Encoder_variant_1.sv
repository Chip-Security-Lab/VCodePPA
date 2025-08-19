//SystemVerilog
module RLE_Encoder (
    input clk, rst_n, en,
    input [7:0] data_in,
    output reg [15:0] data_out,
    output valid
);
    // Stage 1 registers
    reg [7:0] prev_data_stage1;
    reg [7:0] counter_stage1;
    reg [7:0] data_stage1;
    reg en_stage1;
    
    // Stage 2 registers
    reg [7:0] prev_data_stage2;
    reg [7:0] counter_stage2;
    reg [7:0] data_stage2;
    reg comparison_result_stage2;
    reg counter_overflow_stage2;
    reg en_stage2;
    
    // Stage 3 registers
    reg [7:0] prev_data_stage3;
    reg [7:0] counter_stage3;
    reg [7:0] data_stage3;
    reg update_counter_stage3;
    reg output_data_stage3;
    
    // Pipeline Stage 1: Register inputs and perform comparisons
    always @(posedge clk) begin
        if (!rst_n) begin
            data_stage1 <= 8'b0;
            prev_data_stage1 <= 8'b0;
            counter_stage1 <= 8'b0;
            en_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            prev_data_stage1 <= prev_data_stage3;
            counter_stage1 <= counter_stage3;
            en_stage1 <= en;
        end
    end
    
    // Pipeline Stage 2: Calculate comparison results and make decisions
    always @(posedge clk) begin
        if (!rst_n) begin
            prev_data_stage2 <= 8'b0;
            counter_stage2 <= 8'b0;
            data_stage2 <= 8'b0;
            comparison_result_stage2 <= 1'b0;
            counter_overflow_stage2 <= 1'b0;
            en_stage2 <= 1'b0;
        end else begin
            prev_data_stage2 <= prev_data_stage1;
            counter_stage2 <= counter_stage1;
            data_stage2 <= data_stage1;
            comparison_result_stage2 <= (data_stage1 == prev_data_stage1);
            counter_overflow_stage2 <= (counter_stage1 >= 8'd255);
            en_stage2 <= en_stage1;
        end
    end
    
    // Pipeline Stage 3: Determine control signals for final output
    always @(posedge clk) begin
        if (!rst_n) begin
            prev_data_stage3 <= 8'b0;
            counter_stage3 <= 8'b0;
            data_stage3 <= 8'b0;
            update_counter_stage3 <= 1'b0;
            output_data_stage3 <= 1'b0;
        end else begin
            data_stage3 <= data_stage2;
            
            if (en_stage2) begin
                // Calculate update signals based on comparison results
                update_counter_stage3 <= comparison_result_stage2 && !counter_overflow_stage2;
                output_data_stage3 <= !comparison_result_stage2 || counter_overflow_stage2;
                
                // Update state based on calculated signals
                if (comparison_result_stage2 && !counter_overflow_stage2) begin
                    // Keep the same prev_data and increment counter
                    prev_data_stage3 <= prev_data_stage2;
                    counter_stage3 <= counter_stage2 + 8'd1;
                end else begin
                    // Output current data and reset for new sequence
                    prev_data_stage3 <= data_stage2;
                    counter_stage3 <= 8'd0;
                end
            end else begin
                prev_data_stage3 <= prev_data_stage2;
                counter_stage3 <= counter_stage2;
                update_counter_stage3 <= 1'b0;
                output_data_stage3 <= 1'b0;
            end
        end
    end
    
    // Final output stage
    always @(posedge clk) begin
        if (!rst_n) begin
            data_out <= 16'b0;
        end else if (output_data_stage3) begin
            data_out <= {counter_stage3, prev_data_stage3};
        end
    end
    
    // Valid output signal
    assign valid = (counter_stage3 != 8'd0);
    
endmodule