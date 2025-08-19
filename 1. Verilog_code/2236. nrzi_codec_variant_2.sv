//SystemVerilog
module nrzi_codec (
    input wire clk, rst_n,
    input wire data_in,      // For encoding
    input wire nrzi_in,      // For decoding
    output reg nrzi_out,     // Encoded output
    output reg data_out,     // Decoded output
    output reg data_valid    // Valid decoded bit
);
    // Registers for encoding/decoding processes
    reg prev_level;
    reg prev_nrzi;
    
    // Counter with reduced fan-out
    reg [1:0] bit_counter;
    
    // Pipeline registers for input signals
    reg data_in_pipe;
    reg nrzi_in_pipe;
    
    // Pre-computation signals for improved timing
    reg next_nrzi_out;
    reg next_data_out;
    reg do_process;
    
    // Buffered control signals
    reg [1:0] bit_counter_buff;
    reg prev_level_buff;
    
    // Input buffering - move registers closer to inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_pipe <= 1'b0;
            nrzi_in_pipe <= 1'b0;
        end else begin
            data_in_pipe <= data_in;
            nrzi_in_pipe <= nrzi_in;
        end
    end
    
    // Counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 2'b00;
        end else begin
            bit_counter <= bit_counter + 2'b01;
        end
    end
    
    // Buffer counter and control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter_buff <= 2'b00;
            do_process <= 1'b0;
        end else begin
            bit_counter_buff <= bit_counter;
            do_process <= (bit_counter == 2'b11);
        end
    end
    
    // Pre-computation logic for encoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_level_buff <= 1'b0;
            next_nrzi_out <= 1'b0;
        end else begin
            prev_level_buff <= prev_level;
            // Pre-compute next NRZI output based on current data
            next_nrzi_out <= prev_level_buff ^ ~data_in_pipe;
        end
    end
    
    // NRZI encoding output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nrzi_out <= 1'b0;
            prev_level <= 1'b0;
        end else begin
            if (do_process) begin
                nrzi_out <= next_nrzi_out;
                prev_level <= next_nrzi_out;
            end
        end
    end
    
    // Pre-computation logic for decoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_data_out <= 1'b0;
        end else begin
            // Pre-compute the decoded data out
            next_data_out <= ~(prev_nrzi ^ nrzi_in_pipe);
        end
    end
    
    // NRZI decoding output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
            data_valid <= 1'b0;
            prev_nrzi <= 1'b0;
        end else begin
            // Default state
            data_valid <= 1'b0;
            
            if (do_process) begin
                data_out <= next_data_out;
                data_valid <= 1'b1;
                prev_nrzi <= nrzi_in_pipe;
            end
        end
    end
endmodule