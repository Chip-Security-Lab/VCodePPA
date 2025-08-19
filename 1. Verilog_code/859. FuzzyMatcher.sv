module FuzzyMatcher #(parameter WIDTH=8, THRESHOLD=2) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output match
);
    // XOR to find different bits
    wire [WIDTH-1:0] xor_result = data ^ pattern;
    
    // Count number of set bits (ones) in the XOR result
    // (replacing $countones with manual bit counting)
    integer i;
    reg [7:0] ones_count; // Assuming WIDTH <= 255
    
    always @* begin
        ones_count = 0;
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (xor_result[i]) 
                ones_count = ones_count + 1;
        end
    end
    
    // Match if the number of different bits is less than or equal to threshold
    assign match = (ones_count <= THRESHOLD);
endmodule