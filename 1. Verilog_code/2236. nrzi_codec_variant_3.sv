//SystemVerilog
module nrzi_codec (
    input wire clk, rst_n,
    input wire data_in,      // For encoding
    input wire nrzi_in,      // For decoding
    output reg nrzi_out,     // Encoded output
    output reg data_out,     // Decoded output
    output reg data_valid    // Valid decoded bit
);
    // Pipeline registers for encoding path
    reg data_in_stage1;
    reg data_in_stage2;
    reg prev_level_stage1;
    reg prev_level_stage2;
    reg prev_level_stage3;
    reg transition_needed_stage2;
    reg transition_needed_stage3;
    reg nrzi_out_stage3;
    
    // Pipeline registers for bit counter
    reg [1:0] bit_counter;
    reg [1:0] bit_counter_stage1;
    reg [1:0] bit_counter_stage2;
    reg new_bit_stage1;
    reg new_bit_stage2;
    
    // Pipeline stage 1: Capture inputs and determine if at start of new bit
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 1'b0;
            bit_counter <= 2'b00;
            bit_counter_stage1 <= 2'b00;
            new_bit_stage1 <= 1'b0;
            prev_level_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            bit_counter <= bit_counter + 1'b1;
            bit_counter_stage1 <= bit_counter;
            new_bit_stage1 <= (bit_counter == 2'b00);
            prev_level_stage1 <= prev_level_stage3;
        end
    end
    
    // Pipeline stage 2: Determine if transition needed
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage2 <= 1'b0;
            new_bit_stage2 <= 1'b0;
            bit_counter_stage2 <= 2'b00;
            prev_level_stage2 <= 1'b0;
            transition_needed_stage2 <= 1'b0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            new_bit_stage2 <= new_bit_stage1;
            bit_counter_stage2 <= bit_counter_stage1;
            prev_level_stage2 <= prev_level_stage1;
            
            // Determine if transition is needed (for '0' bits)
            transition_needed_stage2 <= new_bit_stage1 && (data_in_stage1 == 1'b0);
        end
    end
    
    // Pipeline stage 3: Generate output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_level_stage3 <= 1'b0;
            transition_needed_stage3 <= 1'b0;
            nrzi_out_stage3 <= 1'b0;
            nrzi_out <= 1'b0;
        end else begin
            prev_level_stage3 <= prev_level_stage2;
            transition_needed_stage3 <= transition_needed_stage2;
            
            // Generate output based on transition decision
            if (new_bit_stage2) begin
                if (transition_needed_stage2)
                    nrzi_out_stage3 <= ~prev_level_stage2;
                else
                    nrzi_out_stage3 <= prev_level_stage2;
            end else begin
                nrzi_out_stage3 <= nrzi_out_stage3;
            end
            
            // Final output register
            nrzi_out <= nrzi_out_stage3;
        end
    end
    
    // Decoding logic pipeline stages would be implemented here
    // Currently stubbed out as in original code
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
            data_valid <= 1'b0;
        end else begin
            data_out <= 1'b0;
            data_valid <= 1'b0;
        end
    end
    
endmodule