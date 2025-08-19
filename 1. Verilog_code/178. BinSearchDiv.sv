module BinSearchDiv(
    input [7:0] D, d,
    output [7:0] Q
);
    reg [7:0] low, high, mid, result;
    
    always @(*) begin
        low = 0;
        high = D;
        result = high;
        
        // Implement binary search for division as unrolled iterations
        // First iteration
        mid = (low + high) >> 1;
        if (mid * d <= D) low = mid + 1;
        else high = mid - 1;
        
        // Second iteration
        mid = (low + high) >> 1;
        if (mid * d <= D) low = mid + 1;
        else high = mid - 1;
        
        // Third iteration
        mid = (low + high) >> 1;
        if (mid * d <= D) low = mid + 1;
        else high = mid - 1;
        
        // Fourth iteration
        mid = (low + high) >> 1;
        if (mid * d <= D) low = mid + 1;
        else high = mid - 1;
        
        // Fifth iteration
        mid = (low + high) >> 1;
        if (mid * d <= D) low = mid + 1;
        else high = mid - 1;
        
        // Sixth iteration
        mid = (low + high) >> 1;
        if (mid * d <= D) low = mid + 1;
        else high = mid - 1;
        
        // Seventh iteration
        mid = (low + high) >> 1;
        if (mid * d <= D) low = mid + 1;
        else high = mid - 1;
        
        // The final high value is our result
        result = high;
    end
    
    assign Q = result;
endmodule