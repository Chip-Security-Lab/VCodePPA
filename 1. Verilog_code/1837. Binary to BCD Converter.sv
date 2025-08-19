module bin2bcd_converter #(parameter BIN_WIDTH = 8, parameter DIGITS = 3) (
    input  wire [BIN_WIDTH-1:0] binary_in,
    output reg  [DIGITS*4-1:0]  bcd_out
);
    integer i, j;
    
    always @(*) begin
        // Initialize BCD with zeros
        bcd_out = {DIGITS*4{1'b0}};
        
        // Double dabble algorithm (shift & add 3)
        for (i = BIN_WIDTH-1; i >= 0; i = i - 1) begin
            // Shift BCD left by 1 bit
            bcd_out = {bcd_out[DIGITS*4-2:0], binary_in[i]};
            
            // Check if any BCD digit exceeds 4
            for (j = 0; j < DIGITS; j = j + 1) begin
                if (bcd_out[j*4 +: 4] > 4'd4)
                    bcd_out[j*4 +: 4] = bcd_out[j*4 +: 4] + 4'd3;
            end
        end
    end
endmodule