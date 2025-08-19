//SystemVerilog
module Multiplier1(
    input [7:0] a, b,
    output reg [15:0] result
);
    // Booth multiplier implementation
    reg [8:0] multiplicand;
    reg [8:0] multiplier;
    reg [16:0] partial_product0, partial_product1, partial_product2, partial_product3;
    reg [16:0] accumulator;
    
    always @(*) begin
        // Initialize
        multiplicand = {1'b0, a};
        multiplier = {1'b0, b};
        accumulator = 17'b0;
        
        // Unrolled Booth encoding and multiplication - Iteration 0
        case ({multiplier[1], multiplier[0], 1'b0})
            3'b000, 3'b111: partial_product0 = 17'b0;
            3'b001, 3'b010: partial_product0 = {multiplicand, 8'b0};
            3'b011: partial_product0 = {multiplicand, 8'b0} << 1;
            3'b100: partial_product0 = -({multiplicand, 8'b0} << 1);
            3'b101, 3'b110: partial_product0 = -{multiplicand, 8'b0};
            default: partial_product0 = 17'b0;
        endcase
        
        // Unrolled Booth encoding and multiplication - Iteration 1
        case ({multiplier[3], multiplier[2], multiplier[1]})
            3'b000, 3'b111: partial_product1 = 17'b0;
            3'b001, 3'b010: partial_product1 = {multiplicand, 8'b0};
            3'b011: partial_product1 = {multiplicand, 8'b0} << 1;
            3'b100: partial_product1 = -({multiplicand, 8'b0} << 1);
            3'b101, 3'b110: partial_product1 = -{multiplicand, 8'b0};
            default: partial_product1 = 17'b0;
        endcase
        
        // Unrolled Booth encoding and multiplication - Iteration 2
        case ({multiplier[5], multiplier[4], multiplier[3]})
            3'b000, 3'b111: partial_product2 = 17'b0;
            3'b001, 3'b010: partial_product2 = {multiplicand, 8'b0};
            3'b011: partial_product2 = {multiplicand, 8'b0} << 1;
            3'b100: partial_product2 = -({multiplicand, 8'b0} << 1);
            3'b101, 3'b110: partial_product2 = -{multiplicand, 8'b0};
            default: partial_product2 = 17'b0;
        endcase
        
        // Unrolled Booth encoding and multiplication - Iteration 3
        case ({multiplier[7], multiplier[6], multiplier[5]})
            3'b000, 3'b111: partial_product3 = 17'b0;
            3'b001, 3'b010: partial_product3 = {multiplicand, 8'b0};
            3'b011: partial_product3 = {multiplicand, 8'b0} << 1;
            3'b100: partial_product3 = -({multiplicand, 8'b0} << 1);
            3'b101, 3'b110: partial_product3 = -{multiplicand, 8'b0};
            default: partial_product3 = 17'b0;
        endcase
        
        // Compute final result using shift and add
        accumulator = partial_product0 + 
                     (partial_product1 << 2) + 
                     (partial_product2 << 4) + 
                     (partial_product3 << 6);
        
        result = accumulator[15:0];
    end
endmodule