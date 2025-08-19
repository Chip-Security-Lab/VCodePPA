//SystemVerilog
// Top level module - SR Latch controller
module sr_latch (
    input  wire s,
    input  wire r,
    output wire q
);
    // Optimized direct implementation
    // Eliminates intermediate signals and modules for better PPA
    
    wire set_enable;   // Set condition signal
    wire reset_enable; // Reset condition signal
    
    // Simplified boolean expressions
    assign set_enable = s & ~r;
    assign reset_enable = ~s & r;
    
    // Optimized output with continuous assignment
    // Avoids always block and uses SR latch behavior
    assign q = set_enable ? 1'b1 : (reset_enable ? 1'b0 : q);

endmodule