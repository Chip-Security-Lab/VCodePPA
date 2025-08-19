module parity_generator #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] data_i,
    input  wire             odd_parity,  // 0=even, 1=odd
    output wire             parity_bit
);
    wire even_parity_result;
    
    // Calculate even parity (1 when odd number of 1s)
    assign even_parity_result = ^data_i;
    
    // Adjust for odd/even selection
    assign parity_bit = even_parity_result ^ odd_parity;
endmodule