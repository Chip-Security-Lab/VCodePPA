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
        end else begin
            bit_counter <= bit_counter + 1'b1;
            if (bit_counter == 2'b00) begin // Start of new bit
                if (data_in == 1'b0) // Encode '0' as transition
                    nrzi_out <= ~prev_level;
                else // Encode '1' as no transition
                    nrzi_out <= prev_level;
                prev_level <= nrzi_out;
            end
        end
    end
    
    // NRZ-I decoder logic would be implemented here
endmodule