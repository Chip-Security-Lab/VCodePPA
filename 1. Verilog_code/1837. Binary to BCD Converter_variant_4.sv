//SystemVerilog
module bin2bcd_converter #(parameter BIN_WIDTH = 8, parameter DIGITS = 3) (
    input  wire [BIN_WIDTH-1:0] binary_in,
    output reg  [DIGITS*4-1:0]  bcd_out
);
    integer i, j;
    reg [3:0] digit;
    
    always @(*) begin
        // Initialize BCD with zeros
        bcd_out = {DIGITS*4{1'b0}};
        
        // Double dabble algorithm with optimized comparison
        for (i = BIN_WIDTH-1; i >= 0; i = i - 1) begin
            // Shift BCD left by 1 bit
            bcd_out = {bcd_out[DIGITS*4-2:0], binary_in[i]};
            
            // Check if any BCD digit exceeds 4 - optimized comparison
            for (j = 0; j < DIGITS; j = j + 1) begin
                digit = bcd_out[j*4 +: 4];
                // Use range check instead of direct comparison
                // Check if digit is 5-9 in one comparison
                if (digit[3:1] == 3'b010 || digit[3:2] == 2'b11)
                    bcd_out[j*4 +: 4] = digit + 4'd3;
            end
        end
    end
endmodule