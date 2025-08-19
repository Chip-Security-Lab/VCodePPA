//SystemVerilog
// Top level module
module Compare_XNOR(
    input [7:0] a, b,
    output eq_flag
);
    // Manchester carry chain inspired comparison
    wire [8:0] carry_chain;
    
    // Initialize the carry chain
    assign carry_chain[0] = 1'b1;
    
    // Generate comparison chain using carry propagation concept
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: comp_chain
            // Using carry chain structure inspired by Manchester carry chain
            // P (propagate) becomes XNOR for equality comparison
            assign carry_chain[i+1] = carry_chain[i] & ~(a[i] ^ b[i]);
        end
    endgenerate
    
    // Final equality result is at the end of the chain
    assign eq_flag = carry_chain[8];
endmodule