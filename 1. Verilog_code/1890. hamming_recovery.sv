module hamming_recovery (
    input wire clk,
    input wire [11:0] encoded,
    output reg [7:0] decoded,
    output reg error_detected,
    output reg error_corrected
);
    reg [3:0] syndrome;
    reg [11:0] corrected;
    
    always @(posedge clk) begin
        // Calculate syndrome
        syndrome[0] = ^{encoded[0], encoded[2], encoded[4], encoded[6], encoded[8], encoded[10]};
        syndrome[1] = ^{encoded[1], encoded[2], encoded[5], encoded[6], encoded[9], encoded[10]};
        syndrome[2] = ^{encoded[3], encoded[4], encoded[5], encoded[6], encoded[11]};
        syndrome[3] = ^{encoded[7], encoded[8], encoded[9], encoded[10], encoded[11]};
        
        // Process syndrome
        error_detected = (syndrome != 4'b0000);
        
        if (error_detected) begin
            // Correct bit if error position is valid
            if (syndrome <= 12) begin
                corrected = encoded;
                corrected[syndrome-1] = ~corrected[syndrome-1];
                error_corrected = 1'b1;
            end else begin
                corrected = encoded;
                error_corrected = 1'b0;
            end
        end else begin
            corrected = encoded;
            error_corrected = 1'b0;
        end
        
        // Extract data bits
        decoded = {corrected[11], corrected[10], corrected[9], corrected[8], 
                   corrected[6], corrected[5], corrected[4], corrected[2]};
    end
endmodule