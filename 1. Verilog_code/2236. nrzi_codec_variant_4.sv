//SystemVerilog
module nrzi_codec (
    input wire clk, rst_n,
    input wire data_in,      // For encoding
    input wire nrzi_in,      // For decoding
    output reg nrzi_out,     // Encoded output
    output reg data_out,     // Decoded output
    output reg data_valid    // Valid decoded bit
);
    reg prev_level;
    reg prev_nrzi;
    reg [1:0] bit_counter;
    
    // NRZ-I encoding: transition for '0', no transition for '1'
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nrzi_out <= 1'b0;
            prev_level <= 1'b0;
            bit_counter <= 2'b00;
        end 
        else if (bit_counter == 2'b00) begin
            // Start of new bit - Optimized encoding logic: XOR implementation
            nrzi_out <= prev_level ^ ~data_in;
            prev_level <= prev_level ^ ~data_in; // Update with new value
            bit_counter <= bit_counter + 1'b1;
        end
        else begin
            // Not at bit boundary, just increment counter
            bit_counter <= bit_counter + 1'b1;
        end
    end
    
    // NRZ-I decoder implementation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
            data_valid <= 1'b0;
            prev_nrzi <= 1'b0;
        end
        else if (bit_counter == 2'b00) begin
            // At bit boundary - detect transitions
            data_out <= ~(prev_nrzi ^ nrzi_in);
            data_valid <= 1'b1;
            prev_nrzi <= nrzi_in;
        end
        else begin
            // Not at bit boundary
            data_valid <= 1'b0;
            // Keep other values unchanged
        end
    end
endmodule