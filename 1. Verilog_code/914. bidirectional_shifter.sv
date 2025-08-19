module bidirectional_shifter(
    input [31:0] data,
    input [4:0] shift_amount,
    input direction,  // 0: left, 1: right
    output [31:0] result
);
    // Implementation uses conditional operator for direction
    assign result = direction ? 
                   (data >> shift_amount) :  // Shift right if direction=1
                   (data << shift_amount);   // Shift left if direction=0
                   
    // This is a purely combinational module
    // Direction control allows versatile shifting operations
    // Direction=0: Left shift (fill with 0s from right)
    // Direction=1: Right shift (fill with 0s from left)
endmodule