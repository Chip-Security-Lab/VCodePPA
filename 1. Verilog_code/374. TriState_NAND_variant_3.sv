//SystemVerilog
module TriState_NAND(
    input en,
    input [3:0] a, b,
    output reg [3:0] y
);
    // Internal signals for Booth multiplier
    reg [7:0] booth_result;
    
    always @(*) begin
        if (en) begin
            // Calculate using Booth multiplier and then apply NAND behavior
            booth_result = booth_multiply(a, b);
            // Take the lower 4 bits and invert to maintain NAND behavior
            y = ~(booth_result[3:0]);
        end else begin
            y = 4'bzzzz;
        end
    end
    
    // Booth multiplication function
    function [7:0] booth_multiply;
        input [3:0] multiplicand;
        input [3:0] multiplier;
        
        reg [8:0] A, S, P;
        reg [3:0] inverted_multiplicand;
        integer i;
        
        begin
            // Initialize registers
            inverted_multiplicand = ~multiplicand + 1'b1;  // 2's complement
            A = {multiplicand, 4'b0000, 1'b0};
            S = {inverted_multiplicand, 4'b0000, 1'b0};
            P = {4'b0000, multiplier, 1'b0};
            
            // Booth algorithm
            for (i = 0; i < 4; i = i + 1) begin
                case (P[1:0])
                    2'b01: P = P + A;
                    2'b10: P = P + S;
                    default: P = P; // No operation for 00 or 11
                endcase
                
                // Arithmetic right shift
                P = {P[8], P[8:1]};
            end
            
            // Return result
            booth_multiply = P[8:1];
        end
    endfunction
endmodule