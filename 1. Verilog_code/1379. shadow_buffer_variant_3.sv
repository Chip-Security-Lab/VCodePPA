//SystemVerilog
module shadow_buffer (
    input wire clk,
    input wire rst_n,                // Added reset for better synchronization
    input wire [31:0] data_in,
    input wire data_valid,           // Replaced 'capture' with 'data_valid'
    output reg data_ready,           // Added 'data_ready' as handshake signal
    input wire output_ready,         // Replaced 'update' with 'output_ready'
    output reg output_valid,         // Added 'output_valid' as handshake signal
    output reg [31:0] data_out
);
    reg [31:0] shadow;
    reg data_captured;               // Flag to track if data has been captured
    
    // Reset logic for input interface
    always @(negedge rst_n) begin
        if (!rst_n) begin
            shadow <= 32'b0;
            data_ready <= 1'b1;      // Ready to receive by default
            data_captured <= 1'b0;
        end
    end
    
    // Input data capture logic
    always @(posedge clk) begin
        if (rst_n) begin
            if (data_valid && data_ready) begin
                shadow <= data_in;
                data_captured <= 1'b1;
            end
        end
    end
    
    // Input handshake control logic
    always @(posedge clk) begin
        if (rst_n) begin
            if (data_valid && data_ready) begin
                // Temporarily go not-ready after capture to control flow
                data_ready <= 1'b0;
            end else begin
                // Return to ready state next cycle
                data_ready <= 1'b1;
            end
        end
    end
    
    // Reset logic for output interface
    always @(negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 32'b0;
            output_valid <= 1'b0;
        end
    end
    
    // Output data transfer logic
    always @(posedge clk) begin
        if (rst_n) begin
            if (data_captured && !output_valid) begin
                data_out <= shadow;
                output_valid <= 1'b1;
                data_captured <= 1'b0;  // Reset capture flag after use
            end
        end
    end
    
    // Output handshake completion logic
    always @(posedge clk) begin
        if (rst_n) begin
            if (output_valid && output_ready) begin
                // Handshake complete
                output_valid <= 1'b0;
            end
        end
    end
endmodule