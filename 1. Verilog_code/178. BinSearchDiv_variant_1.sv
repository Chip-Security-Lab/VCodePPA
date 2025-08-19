//SystemVerilog
module RippleCarryAdder(
    input [7:0] A, B,
    output [7:0] Sum
);
    wire [7:0] C;
    
    // Generate carry chain
    assign C[0] = 1'b0;
    assign C[1] = (A[0] & B[0]) | ((A[0] ^ B[0]) & C[0]);
    assign C[2] = (A[1] & B[1]) | ((A[1] ^ B[1]) & C[1]);
    assign C[3] = (A[2] & B[2]) | ((A[2] ^ B[2]) & C[2]);
    assign C[4] = (A[3] & B[3]) | ((A[3] ^ B[3]) & C[3]);
    assign C[5] = (A[4] & B[4]) | ((A[4] ^ B[4]) & C[4]);
    assign C[6] = (A[5] & B[5]) | ((A[5] ^ B[5]) & C[5]);
    assign C[7] = (A[6] & B[6]) | ((A[6] ^ B[6]) & C[6]);
    
    // Generate sum
    assign Sum[0] = A[0] ^ B[0] ^ C[0];
    assign Sum[1] = A[1] ^ B[1] ^ C[1];
    assign Sum[2] = A[2] ^ B[2] ^ C[2];
    assign Sum[3] = A[3] ^ B[3] ^ C[3];
    assign Sum[4] = A[4] ^ B[4] ^ C[4];
    assign Sum[5] = A[5] ^ B[5] ^ C[5];
    assign Sum[6] = A[6] ^ B[6] ^ C[6];
    assign Sum[7] = A[7] ^ B[7] ^ C[7];
endmodule

module BinSearchDiv(
    input [7:0] D, d,
    output [7:0] Q
);
    reg [7:0] low, high, mid, result;
    wire [7:0] sum_out;
    
    RippleCarryAdder adder(
        .A(low),
        .B(high),
        .Sum(sum_out)
    );
    
    always @(*) begin
        low = 0;
        high = D;
        result = high;
        
        // Implement binary search for division as unrolled iterations
        // First iteration
        mid = sum_out >> 1;
        if (mid * d <= D) low = mid + 1;
        else high = mid - 1;
        
        // Second iteration
        mid = sum_out >> 1;
        if (mid * d <= D) low = mid + 1;
        else high = mid - 1;
        
        // Third iteration
        mid = sum_out >> 1;
        if (mid * d <= D) low = mid + 1;
        else high = mid - 1;
        
        // Fourth iteration
        mid = sum_out >> 1;
        if (mid * d <= D) low = mid + 1;
        else high = mid - 1;
        
        // Fifth iteration
        mid = sum_out >> 1;
        if (mid * d <= D) low = mid + 1;
        else high = mid - 1;
        
        // Sixth iteration
        mid = sum_out >> 1;
        if (mid * d <= D) low = mid + 1;
        else high = mid - 1;
        
        // Seventh iteration
        mid = sum_out >> 1;
        if (mid * d <= D) low = mid + 1;
        else high = mid - 1;
        
        // The final high value is our result
        result = high;
    end
    
    assign Q = result;
endmodule