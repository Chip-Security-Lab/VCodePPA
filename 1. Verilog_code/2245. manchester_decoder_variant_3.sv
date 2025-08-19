//SystemVerilog
module manchester_decoder (
    input wire clk,            // System clock input
    input wire rst_n,          // Active low reset
    input wire encoded,        // Manchester encoded input
    output reg decoded,        // Decoded data output
    output reg clk_recovered   // Recovered clock output
);
    // Internal signals
    reg prev_encoded;          // Previous encoded bit value
    reg encoded_edge;          // Edge detection signal
    
    // Edge detection logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_encoded <= 1'b0;
        end else begin
            prev_encoded <= encoded;
        end
    end
    
    // Clock recovery with proper sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_recovered <= 1'b0;
            encoded_edge <= 1'b0;
        end else begin
            encoded_edge <= encoded ^ prev_encoded;  // Edge detection
            clk_recovered <= encoded_edge;           // Recovered clock
        end
    end
    
    // Data decoding with proper sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded <= 1'b0;
        end else if (encoded_edge) begin
            // Sample data on the edge - encoded value determines the bit
            decoded <= ~encoded;
        end
    end
endmodule