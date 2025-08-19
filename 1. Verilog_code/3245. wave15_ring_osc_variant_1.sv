//SystemVerilog
module wave15_ring_osc(
    output wire ring_out
);
    // Use 5-stage ring oscillator instead of 3-stage for better frequency stability
    (* dont_touch = "true" *) wire n1, n2, n3, n4, n5;
    
    // Implement using NAND gates for better power characteristics and to ensure oscillation
    (* dont_touch = "true" *) wire enable = 1'b1; // Enable signal always active
    
    // NAND-based implementation for improved characteristics
    nand #1 nand1 (n1, n5, enable);
    not  #1 inv1  (n2, n1);
    not  #1 inv2  (n3, n2);
    not  #1 inv3  (n4, n3);
    not  #1 inv4  (n5, n4);
    
    // Buffer output with non-inverting buffer for better driving capability
    assign ring_out = n5;
endmodule