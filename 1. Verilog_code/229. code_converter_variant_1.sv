//SystemVerilog
module code_converter (
    input [2:0] binary,
    output [2:0] gray,
    output [7:0] one_hot
);
    // Gray code conversion
    assign gray = binary ^ (binary >> 1);
    
    // One-hot encoding using barrel shifter structure
    reg [7:0] one_hot_shift;
    
    always @(*) begin
        // Initialize with first bit set to 1
        one_hot_shift = 8'b00000001;
        
        // First barrel shifter stage - shift by 0 or 4 positions
        if (binary[2])
            one_hot_shift = {one_hot_shift[3:0], one_hot_shift[7:4]};
            
        // Second barrel shifter stage - shift by 0 or 2 positions
        if (binary[1])
            one_hot_shift = {one_hot_shift[5:0], one_hot_shift[7:6]};
            
        // Third barrel shifter stage - shift by 0 or 1 position
        if (binary[0])
            one_hot_shift = {one_hot_shift[6:0], one_hot_shift[7]};
    end
    
    assign one_hot = one_hot_shift;
endmodule