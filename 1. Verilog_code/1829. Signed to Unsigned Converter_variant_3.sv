//SystemVerilog
module signed2unsigned_unit #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0]   signed_in,
    output wire [WIDTH-1:0]   unsigned_out,
    output wire               overflow
);
    // LUT for 4-bit conversion (negative number to positive)
    reg [3:0] lut_low [0:15];
    reg [3:0] lut_high [0:15];
    
    // Internal signals
    wire is_negative;
    wire [3:0] lower_nibble, upper_nibble;
    wire [3:0] converted_lower, converted_upper;
    wire carry_from_low;
    
    // Initialize LUTs - precomputed values for 2's complement conversion
    initial begin
        // Lower nibble LUT (including carry out)
        lut_low[4'b0000] = 4'b0000; // 0 -> 0
        lut_low[4'b0001] = 4'b0001; // 1 -> 1
        lut_low[4'b0010] = 4'b0010; // 2 -> 2
        lut_low[4'b0011] = 4'b0011; // 3 -> 3
        lut_low[4'b0100] = 4'b0100; // 4 -> 4
        lut_low[4'b0101] = 4'b0101; // 5 -> 5
        lut_low[4'b0110] = 4'b0110; // 6 -> 6
        lut_low[4'b0111] = 4'b0111; // 7 -> 7
        lut_low[4'b1000] = 4'b1000; // 8 -> 8
        lut_low[4'b1001] = 4'b1001; // 9 -> 9
        lut_low[4'b1010] = 4'b1010; // 10 -> 10
        lut_low[4'b1011] = 4'b1011; // 11 -> 11
        lut_low[4'b1100] = 4'b1100; // 12 -> 12
        lut_low[4'b1101] = 4'b1101; // 13 -> 13
        lut_low[4'b1110] = 4'b1110; // 14 -> 14
        lut_low[4'b1111] = 4'b1111; // 15 -> 15
        
        // Upper nibble LUT
        lut_high[4'b0000] = 4'b0000; // 0 -> 0
        lut_high[4'b0001] = 4'b0001; // 1 -> 1
        lut_high[4'b0010] = 4'b0010; // 2 -> 2
        lut_high[4'b0011] = 4'b0011; // 3 -> 3
        lut_high[4'b0100] = 4'b0100; // 4 -> 4
        lut_high[4'b0101] = 4'b0101; // 5 -> 5
        lut_high[4'b0110] = 4'b0110; // 6 -> 6
        lut_high[4'b0111] = 4'b0111; // 7 -> 7
        lut_high[4'b1000] = 4'b0000; // 8 -> 0+8 (after offset)
        lut_high[4'b1001] = 4'b0001; // 9 -> 1+8
        lut_high[4'b1010] = 4'b0010; // 10 -> 2+8
        lut_high[4'b1011] = 4'b0011; // 11 -> 3+8
        lut_high[4'b1100] = 4'b0100; // 12 -> 4+8
        lut_high[4'b1101] = 4'b0101; // 13 -> 5+8
        lut_high[4'b1110] = 4'b0110; // 14 -> 6+8
        lut_high[4'b1111] = 4'b0111; // 15 -> 7+8
    end
    
    // Split input into nibbles
    assign lower_nibble = signed_in[3:0];
    assign upper_nibble = signed_in[7:4];
    
    // Detect negative number
    assign is_negative = signed_in[WIDTH-1];
    
    // For positive numbers, use directly; for negative, use LUT
    assign converted_lower = is_negative ? ~lower_nibble + 1'b1 : lower_nibble;
    
    // Compute carry from lower nibble conversion
    assign carry_from_low = is_negative && (lower_nibble == 4'b0000);
    
    // Process upper nibble with carry consideration
    assign converted_upper = is_negative ? ~upper_nibble + carry_from_low : upper_nibble;
    
    // Handle the conversion using the LUTs and conditionals
    wire [3:0] unsigned_lower = is_negative ? lut_low[converted_lower] : lower_nibble;
    wire [3:0] unsigned_upper = lut_high[upper_nibble];
    
    // Combine the nibbles to form the final output
    assign unsigned_out = {unsigned_upper, unsigned_lower};
    
    // Overflow detection (unchanged)
    assign overflow = signed_in[WIDTH-1];
endmodule