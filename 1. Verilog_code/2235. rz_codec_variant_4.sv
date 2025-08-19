//SystemVerilog
module rz_codec (
    input wire clk, rst_n,
    input wire data_in,       // For encoding
    input wire rz_in,         // For decoding
    output reg rz_out,        // Encoded output
    output reg data_out,      // Decoded output
    output reg valid_out      // Valid decoded bit
);
    // Pipeline stage control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Pipeline Stage 1: Input sampling and phase tracking
    reg [1:0] bit_phase;
    reg data_in_stage1;
    reg rz_in_stage1;
    
    // Parallel prefix adder signals for bit_phase counter
    wire [1:0] bit_phase_next;
    wire [1:0] p, g;
    wire c_out;
    
    // Generate propagate and generate signals
    assign p[0] = bit_phase[0];
    assign p[1] = bit_phase[1];
    assign g[0] = 1'b0;
    assign g[1] = bit_phase[1] & bit_phase[0];
    
    // Parallel prefix computation
    wire c1;
    assign c1 = g[0];
    assign c_out = g[1] | (p[1] & c1);
    
    // Sum computation
    assign bit_phase_next[0] = bit_phase[0] ^ 1'b1;
    assign bit_phase_next[1] = bit_phase[1] ^ c1;
    
    // Stage 1: Bit phase counter and input sampling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_phase <= 2'b00;
            data_in_stage1 <= 1'b0;
            rz_in_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            bit_phase <= bit_phase_next;
            data_in_stage1 <= data_in;
            rz_in_stage1 <= rz_in;
            valid_stage1 <= 1'b1;  // Activate pipeline after reset
        end
    end
    
    // Pipeline Stage 2: Processing
    reg [1:0] bit_phase_stage2;
    reg data_in_stage2;
    reg rz_in_stage2;
    reg rz_temp;
    reg [1:0] sample_count;
    reg data_sampled;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_phase_stage2 <= 2'b00;
            data_in_stage2 <= 1'b0;
            rz_in_stage2 <= 1'b0;
            rz_temp <= 1'b0;
            sample_count <= 2'b00;
            data_sampled <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            bit_phase_stage2 <= bit_phase;
            data_in_stage2 <= data_in_stage1;
            rz_in_stage2 <= rz_in_stage1;
            valid_stage2 <= valid_stage1;
            
            // RZ encoding processing
            case (bit_phase)
                2'b00: rz_temp <= data_in_stage1; // First half of bit is high for '1'
                2'b10: rz_temp <= 1'b0;          // Second half always returns to zero
            endcase
            
            // RZ decoding processing - sample counter
            if (bit_phase == 2'b00) begin
                sample_count <= 2'b00;
                data_sampled <= 1'b0;
            end
            else begin
                sample_count <= sample_count + 1'b1;
                // Sample on first half of the bit period
                if (sample_count == 2'b01) begin
                    data_sampled <= rz_in_stage1;
                end
            end
        end
    end
    
    // Pipeline Stage 3: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rz_out <= 1'b0;
            data_out <= 1'b0;
            valid_out <= 1'b0;
            valid_stage3 <= 1'b0;
        end
        else begin
            valid_stage3 <= valid_stage2;
            
            // Final output registration
            rz_out <= rz_temp;
            
            // Generate decoded output
            if (bit_phase_stage2 == 2'b10 && valid_stage2) begin
                data_out <= data_sampled;
                valid_out <= 1'b1;
            end
            else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule