//SystemVerilog
module Segmented_XNOR(
    input clk,          // Clock signal
    input rst_n,        // Active-low reset
    
    // Input interface
    input [7:0] high,   // High input data
    input [7:0] low,    // Low input data
    input valid_in,     // Input data valid signal
    output ready_out,   // Ready to accept input data
    
    // Output interface
    output reg [7:0] res,     // Result output
    output reg valid_out,     // Output data valid signal
    input ready_in            // Downstream ready to accept data
);
    
    // Internal signals and registers
    reg processing;
    
    // Intermediate signals for computation
    wire [3:0] xor_high_low, xor_low_high;
    
    // Compute XOR results combinationally to reduce critical path
    assign xor_high_low = high[7:4] ^ low[3:0];
    assign xor_low_high = high[3:0] ^ low[7:4];
    
    // Ready to accept new data when not processing or when current result is accepted
    assign ready_out = !processing || (valid_out && ready_in);
    
    // Control logic with forward-retimed registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res <= 8'b0;
            valid_out <= 1'b0;
            processing <= 1'b0;
        end else begin
            // Input handshake
            if (valid_in && ready_out) begin
                // Apply forward register retiming by directly storing
                // the inverted XOR results instead of input values
                res[7:4] <= ~xor_high_low;
                res[3:0] <= ~xor_low_high;
                valid_out <= 1'b1;
                processing <= 1'b1;
            end
            
            // Output handshake
            if (valid_out && ready_in) begin
                valid_out <= 1'b0;
                processing <= 1'b0;
            end
        end
    end
    
endmodule