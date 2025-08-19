module Sub2(input [3:0] x, y, output [3:0] diff, output borrow);
    wire [3:0] y_inv;
    wire [3:0] sum;
    wire [3:0] temp_diff;
    wire temp_borrow;
    
    // Invert y when x < y
    assign y_inv = (x < y) ? ~y : y;
    
    // Add x and inverted y (or y if x >= y)
    assign sum = x + y_inv;
    
    // Calculate difference and borrow
    assign temp_diff = (x < y) ? ~sum : sum;
    assign temp_borrow = (x < y) ? 1'b1 : 0;
    
    // Final outputs
    assign diff = temp_diff;
    assign borrow = temp_borrow;
endmodule