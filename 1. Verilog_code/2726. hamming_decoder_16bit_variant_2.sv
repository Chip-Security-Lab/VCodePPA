//SystemVerilog
module hamming_decoder_16bit(
    input clk, rst,
    input [21:0] encoded,
    output reg [15:0] decoded,
    output reg [4:0] error_pos
);
    wire [4:0] syndrome;
    
    // Optimized syndrome calculation using combinational logic
    assign syndrome[0] = ^(encoded & 22'b0101010101010101010100);
    assign syndrome[1] = ^(encoded & 22'b0110011001100110011000);
    assign syndrome[2] = ^(encoded & 22'b0111100001111000011110);
    assign syndrome[3] = ^(encoded & 22'b0111111110000000000000);
    assign syndrome[4] = ^encoded;
    
    always @(posedge clk) begin
        if (rst) begin
            decoded <= 16'b0;
            error_pos <= 5'b0;
        end else begin
            error_pos <= syndrome;
            // Extract data bits directly in one operation
            decoded <= {encoded[21:17], encoded[15:9], encoded[7:4], encoded[2]};
        end
    end
endmodule