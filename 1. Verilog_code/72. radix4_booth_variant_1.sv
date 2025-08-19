//SystemVerilog
module radix4_booth (
    input [7:0] X,
    input [7:0] Y,
    output [15:0] Product
);
    // Internal signals
    reg [15:0] result;
    reg [16:0] A, S, P;
    wire [8:0] Y_extended;
    
    // Extended Y value with padding
    assign Y_extended = {Y, 1'b0};
    
    always @(*) begin
        // Initialize A and S (multiplicand and its negative, sign-extended)
        // A = X extended to 17 bits
        A = {{9{X[7]}}, X};
        
        // S = -X extended to 17 bits, calculated as the 17-bit two's complement of A
        S = (~A + 1'b1);
        
        // P = Partial product register, initialized with extended multiplier Y
        P = {8'b0, Y_extended};
        
        // Booth algorithm - 4 iterations for 8-bit input
        for (integer i = 0; i < 4; i = i + 1) begin
            case (P[2:0])
                3'b001, 3'b010: P = P + A;  // Add A (X)
                3'b011: P = P + {A[15:0], 1'b0};  // Add 2A (2X)
                3'b100: P = P + {S[15:0], 1'b0};  // Add 2S (2(-X))
                3'b101, 3'b110: P = P + S;  // Add S (-X)
                default: P = P;  // No operation for 000 or 111 (0 or -2X)
            endcase
            
            // Arithmetic shift right by 2
            P = {{2{P[16]}}, P[16:2]};
        end
        
        // Final result (16-bit product)
        result = P[16:1];
    end
    
    // Output assignment
    assign Product = result;
endmodule