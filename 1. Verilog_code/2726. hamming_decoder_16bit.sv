module hamming_decoder_16bit(
    input clk, rst,
    input [21:0] encoded,
    output reg [15:0] decoded,
    output reg [4:0] error_pos
);
    reg [4:0] syndrome;
    
    always @(posedge clk) begin
        if (rst) begin
            decoded <= 16'b0;
            error_pos <= 5'b0;
        end else begin
            // Syndrome calculation (simplified)
            syndrome[0] <= ^(encoded & 22'b0101_0101_0101_0101_0101_0);
            syndrome[1] <= ^(encoded & 22'b0110_0110_0110_0110_0110_0);
            syndrome[2] <= ^(encoded & 22'b0111_1000_0111_1000_0111_1);
            syndrome[3] <= ^(encoded & 22'b0111_1111_1000_0000_0000_0);
            syndrome[4] <= ^encoded;
            
            error_pos <= syndrome;
            // Decode and correct (partial implementation)
            decoded <= {encoded[21:17], encoded[15:9], encoded[7:4], encoded[2]};
        end
    end
endmodule