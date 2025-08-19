module async_shift_feedback #(
    parameter LENGTH = 8,
    parameter TAPS = 4'b1001  // Example: taps at positions 0 and 3
)(
    input data_in,
    input [LENGTH-1:0] current_reg,
    output next_bit,
    output [LENGTH-1:0] next_reg
);
    wire feedback;
    
    // Calculate feedback from tapped positions
    assign feedback = ^(current_reg & TAPS);
    
    // Calculate next bit from input and feedback
    assign next_bit = feedback ^ data_in;
    
    // Shift register update
    assign next_reg = {current_reg[LENGTH-2:0], next_bit};
endmodule