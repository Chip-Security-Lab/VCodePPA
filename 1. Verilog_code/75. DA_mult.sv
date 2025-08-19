module DA_mult (
    input [3:0] x,
    input [3:0] y,
    output [7:0] out
);
    // Distributed Arithmetic implementation for 4x4 bit multiplication
    // Pre-compute partial products
    wire [3:0] pp0, pp1, pp2, pp3;
    
    // Generate partial products based on each bit of y
    assign pp0 = y[0] ? x : 4'b0000;
    assign pp1 = y[1] ? x : 4'b0000;
    assign pp2 = y[2] ? x : 4'b0000;
    assign pp3 = y[3] ? x : 4'b0000;
    
    // Shift and add partial products to get final result
    wire [7:0] shifted_pp1 = {pp1, 1'b0};         // pp1 << 1
    wire [7:0] shifted_pp2 = {pp2, 2'b00};        // pp2 << 2
    wire [7:0] shifted_pp3 = {pp3, 3'b000};       // pp3 << 3
    
    // Final summation
    assign out = {4'b0000, pp0} + shifted_pp1 + shifted_pp2 + shifted_pp3;
endmodule