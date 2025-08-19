//SystemVerilog
module magnitude_comparator_32bit(
    input [31:0] a_vector,
    input [31:0] b_vector,
    output [1:0] comp_result  // 2'b00: equal, 2'b01: a<b, 2'b10: a>b
);
    // Internal signal definitions
    wire signed [32:0] diff;       // Signed difference
    wire is_equal, is_greater;
    
    // Register to hold the computed difference for clarity
    reg signed [32:0] diff_reg;
    
    // Compute the difference in a separate always block for clarity
    always @(*) begin
        diff_reg = {1'b0, a_vector} - {1'b0, b_vector};
    end
    
    // Check equality and greater than conditions
    assign is_equal = (diff_reg == 0);
    assign is_greater = ~diff_reg[32];  // Sign bit is 0 indicates a > b
    
    // Combine results into the output
    assign comp_result = is_equal ? 2'b00 :
                         is_greater ? 2'b10 : 2'b01;
endmodule