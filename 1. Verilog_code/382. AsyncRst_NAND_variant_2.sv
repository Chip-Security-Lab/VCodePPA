//SystemVerilog
module AsyncRst_NAND(
    input rst_n,
    input [3:0] src1, src2,
    output reg [3:0] q
);
    reg [7:0] booth_result;
    
    always @(*) begin
        if (!rst_n) begin
            q = 4'b1111;
        end else begin
            booth_result = booth_multiply(src1, src2);
            // Take only lower 4 bits and invert (to maintain NAND functionality)
            q = ~(booth_result[3:0]);
        end
    end
    
    function [7:0] booth_multiply;
        input [3:0] multiplicand;
        input [3:0] multiplier;
        
        reg [8:0] A;
        reg [8:0] S;
        reg [8:0] P;
        reg [3:0] neg_multiplicand;
        integer i;
        
        begin
            neg_multiplicand = -multiplicand;
            
            // Initialize registers
            A = {multiplicand, 5'b00000};
            S = {neg_multiplicand, 5'b00000};
            P = {4'b0000, multiplier, 1'b0};
            
            // Booth algorithm iteration
            for (i = 0; i < 4; i = i + 1) begin
                case (P[1:0])
                    2'b01: P = han_carlson_adder(P, A);
                    2'b10: P = han_carlson_adder(P, S);
                    default: P = P; // Do nothing for 00 or 11
                endcase
                
                // Arithmetic right shift
                P = {P[8], P[8:1]};
            end
            
            booth_multiply = P[8:1];
        end
    endfunction
    
    function [8:0] han_carlson_adder;
        input [8:0] a;
        input [8:0] b;
        
        reg [8:0] sum;
        reg [8:0] p; // Propagate signals
        reg [8:0] g; // Generate signals
        reg [8:0] pp; // Group propagate signals
        reg [8:0] gg; // Group generate signals
        
        begin
            // Pre-processing: generate p and g signals
            p = a ^ b;
            g = a & b;
            
            // First stage (even bits)
            gg[0] = g[0];
            pp[0] = p[0];
            
            gg[2] = g[2] | (p[2] & g[1]);
            pp[2] = p[2] & p[1];
            
            gg[4] = g[4] | (p[4] & g[3]);
            pp[4] = p[4] & p[3];
            
            gg[6] = g[6] | (p[6] & g[5]);
            pp[6] = p[6] & p[5];
            
            gg[8] = g[8] | (p[8] & g[7]);
            pp[8] = p[8] & p[7];
            
            // Second stage (odd bits - combine)
            gg[1] = g[1] | (p[1] & gg[0]);
            pp[1] = p[1] & pp[0];
            
            gg[3] = g[3] | (p[3] & gg[2]);
            pp[3] = p[3] & pp[2];
            
            gg[5] = g[5] | (p[5] & gg[4]);
            pp[5] = p[5] & pp[4];
            
            gg[7] = g[7] | (p[7] & gg[6]);
            pp[7] = p[7] & pp[6];
            
            // Third stage (long-range connections for even bits)
            gg[2] = gg[2] | (pp[2] & gg[0]);
            gg[6] = gg[6] | (pp[6] & gg[4]);
            
            // Fourth stage (long-range connections for remaining bits)
            gg[3] = gg[3] | (pp[3] & gg[1]);
            gg[4] = gg[4] | (pp[4] & gg[2]);
            gg[5] = gg[5] | (pp[5] & gg[3]);
            gg[7] = gg[7] | (pp[7] & gg[5]);
            
            // Post-processing: generate sum
            sum[0] = p[0];
            sum[1] = p[1] ^ gg[0];
            sum[2] = p[2] ^ gg[1];
            sum[3] = p[3] ^ gg[2];
            sum[4] = p[4] ^ gg[3];
            sum[5] = p[5] ^ gg[4];
            sum[6] = p[6] ^ gg[5];
            sum[7] = p[7] ^ gg[6];
            sum[8] = p[8] ^ gg[7];
            
            han_carlson_adder = sum;
        end
    endfunction
endmodule