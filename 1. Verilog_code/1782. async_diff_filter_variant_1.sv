//SystemVerilog
module async_diff_filter #(
    parameter DATA_SIZE = 10
)(
    input [DATA_SIZE-1:0] current_sample,
    input [DATA_SIZE-1:0] prev_sample,
    output [DATA_SIZE:0] diff_out  // One bit wider to handle negative
);
    // LUT-based subtractor implementation
    wire [7:0] lut_sub_result;
    wire carry_out;
    
    // Instantiate 8-bit LUT-based subtractor (handles common case efficiently)
    lut_assisted_subtractor lut_sub (
        .minuend(current_sample[7:0]),
        .subtrahend(prev_sample[7:0]),
        .difference(lut_sub_result),
        .borrow_out(carry_out)
    );
    
    // Handle the remaining bits for larger data sizes using conditional operator
    wire [DATA_SIZE-8-1:0] high_bits_diff;
    assign high_bits_diff = (DATA_SIZE > 8) ? current_sample[DATA_SIZE-1:8] - prev_sample[DATA_SIZE-1:8] - carry_out : {(DATA_SIZE-8){1'b0}};
    assign diff_out = (DATA_SIZE <= 8) ? {current_sample[DATA_SIZE-1], lut_sub_result[DATA_SIZE-1:0]} : 
                                         {current_sample[DATA_SIZE-1], high_bits_diff, lut_sub_result};
endmodule

module lut_assisted_subtractor (
    input [7:0] minuend,      // a
    input [7:0] subtrahend,   // b
    output [7:0] difference,  // a - b
    output borrow_out         // Borrow output
);
    // LUT-based subtraction for 4-bit chunks
    wire [3:0] lower_diff, upper_diff;
    wire lower_borrow;
    
    // Lower 4-bit subtraction using LUT
    lut_sub_4bit lower_lut (
        .a(minuend[3:0]),
        .b(subtrahend[3:0]),
        .diff(lower_diff),
        .borrow_out(lower_borrow)
    );
    
    // Upper 4-bit subtraction using LUT
    lut_sub_4bit upper_lut (
        .a(minuend[7:4]),
        .b(subtrahend[7:4]),
        .diff(upper_diff),
        .borrow_in(lower_borrow),
        .borrow_out(borrow_out)
    );
    
    // Combine results
    assign difference = {upper_diff, lower_diff};
endmodule

module lut_sub_4bit (
    input [3:0] a,
    input [3:0] b,
    input borrow_in,
    output [3:0] diff,
    output borrow_out
);
    // Internal signals
    reg [3:0] diff_lut;
    reg borrow_lut;
    
    // Compute difference and borrow using lookup approach
    always @(*) begin
        {borrow_lut, diff_lut} = 
            ({borrow_in, a, b} == 9'b0_0000_0000) ? 5'b0_0000 :
            ({borrow_in, a, b} == 9'b0_0001_0000) ? 5'b0_0001 :
            ({borrow_in, a, b} == 9'b0_0010_0011) ? 5'b1_1111 :
            ({borrow_in, a, b} == 9'b0_0100_0101) ? 5'b1_1111 :
            ({borrow_in, a, b} == 9'b0_1000_0111) ? 5'b0_0001 :
            ({borrow_in, a, b} == 9'b0_1111_0111) ? 5'b0_1000 :
            ({borrow_in, a, b} == 9'b1_1000_0111) ? 5'b0_0000 :
            ({borrow_in, a, b} == 9'b1_1111_0111) ? 5'b0_0111 :
            (a - b - borrow_in);
    end
    
    // Assign outputs
    assign diff = diff_lut;
    assign borrow_out = borrow_lut;
endmodule