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
        
        // Double dabble algorithm (shift & add 3)
        i = BIN_WIDTH-1;
        while (i >= 0) begin
            // Shift BCD left by 1 bit
            bcd_out = {bcd_out[DIGITS*4-2:0], binary_in[i]};
            
            // Check if any BCD digit exceeds 4 (optimized comparison)
            j = 0;
            while (j < DIGITS) begin
                digit = bcd_out[j*4 +: 4];
                // Using optimized comparison: digit > 4 when digit[3:2] != 0 or digit == 4'b0101
                if (digit[3:2] != 2'b00 || digit == 4'b0101)
                    bcd_out[j*4 +: 4] = digit + 4'd3;
                j = j + 1;
            end
            i = i - 1;
        end
    end
endmodule