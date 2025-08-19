//SystemVerilog
module diff_manchester_codec (
    input wire clk, rst,
    input wire data_in,           // For encoding
    input wire diff_manch_in,     // For decoding
    output reg diff_manch_out,    // Encoded output
    output reg data_out,          // Decoded output
    output reg data_valid         // Valid decoded bit
);
    reg prev_encoded;
    reg curr_state;
    reg [1:0] sample_count;
    reg mid_bit, last_sample;
    
    // Sample counter management
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sample_count <= 2'b00;
        end else begin
            sample_count <= sample_count + 1'b1;
        end
    end
    
    // Differential Manchester encoder - state determination
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            prev_encoded <= 1'b0;
        end else if (sample_count == 2'b10) begin
            prev_encoded <= diff_manch_out;
        end
    end
    
    // Differential Manchester encoder - output control
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            diff_manch_out <= 1'b0;
        end else if (sample_count == 2'b00) begin
            // Start of bit time - encode data according to differential manchester rules
            if (data_in) begin
                diff_manch_out <= prev_encoded;
            end else begin
                diff_manch_out <= ~prev_encoded;
            end
        end else if (sample_count == 2'b10) begin
            // Mid-bit transition - always flip the output at mid-bit
            diff_manch_out <= ~diff_manch_out;
        end
    end
    
    // Differential Manchester decoder state
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            curr_state <= 1'b0;
            mid_bit <= 1'b0;
            last_sample <= 1'b0;
        end else begin
            last_sample <= diff_manch_in;
            if (sample_count == 2'b10) begin
                mid_bit <= diff_manch_in;
            end
        end
    end
    
    // Differential Manchester decoder output
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            data_out <= 1'b0;
            data_valid <= 1'b0;
        end else if (sample_count == 2'b11) begin
            // End of bit period - validate and output decoded data
            data_valid <= 1'b1;
            // Decode based on whether there was a transition at bit start
            if (last_sample == mid_bit) begin
                data_out <= 1'b1;
            end else begin
                data_out <= 1'b0;
            end
        end else begin
            data_valid <= 1'b0;
        end
    end
    
endmodule