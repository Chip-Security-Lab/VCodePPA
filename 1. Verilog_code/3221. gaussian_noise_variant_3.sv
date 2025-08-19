//SystemVerilog
module gaussian_noise(
    input clk,
    input rst,
    input ready,           // Ready signal from receiver
    output reg valid,      // Valid signal to receiver
    output reg [7:0] data  // Renamed from noise_out to data
);
    reg [15:0] lfsr1, lfsr2;
    wire fb1 = lfsr1[15] ^ lfsr1[14] ^ lfsr1[12] ^ lfsr1[3];
    wire fb2 = lfsr2[15] ^ lfsr2[13] ^ lfsr2[11] ^ lfsr2[7];
    
    // Internal register to store the next noise value
    reg [7:0] next_noise;
    
    always @(posedge clk) begin
        if (rst) begin
            lfsr1 <= 16'hACE1;
            lfsr2 <= 16'h1234;
            next_noise <= 8'h80;
            data <= 8'h80;
            valid <= 1'b0;
        end else begin
            // Always update LFSRs and calculate next noise value
            lfsr1 <= {lfsr1[14:0], fb1};
            lfsr2 <= {lfsr2[14:0], fb2};
            next_noise <= {1'b0, lfsr1[7:1]} + {1'b0, lfsr2[7:1]};
            
            // Valid-Ready handshake logic
            if (valid && ready) begin
                // Transfer completed, update output with next value
                data <= next_noise;
                valid <= 1'b1;  // Keep valid high as we have new data
            end else if (!valid) begin
                // Not valid, set valid high to indicate new data is available
                valid <= 1'b1;
            end
            // If valid is high but ready is low, keep current data and valid signal
        end
    end
endmodule