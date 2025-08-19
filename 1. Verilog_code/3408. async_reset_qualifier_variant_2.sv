//SystemVerilog IEEE 1364-2005 standard
module async_reset_qualifier (
    input wire raw_reset,
    input wire [3:0] qualifiers,
    output wire [3:0] qualified_resets
);
    // Instance the reset qualification submodule
    reset_qualification_logic reset_qual_inst (
        .reset_in(raw_reset),
        .qual_mask(qualifiers),
        .qualified_out(qualified_resets)
    );
endmodule

//SystemVerilog IEEE 1364-2005 standard
module reset_qualification_logic (
    input wire reset_in,
    input wire [3:0] qual_mask,
    output wire [3:0] qualified_out
);
    // Reset qualification core logic
    wire reset_broadcast;
    
    // Broadcast reset signal to all bits
    reset_broadcaster broadcaster_inst (
        .reset_signal(reset_in),
        .reset_vector(reset_broadcast)
    );
    
    // Apply qualification mask
    reset_masking masking_inst (
        .reset_vector(reset_broadcast),
        .qualification_mask(qual_mask),
        .masked_resets(qualified_out)
    );
endmodule

//SystemVerilog IEEE 1364-2005 standard
module reset_broadcaster (
    input wire reset_signal,
    output wire [3:0] reset_vector
);
    // Replicate the reset signal to create a vector
    assign reset_vector = {4{reset_signal}};
endmodule

//SystemVerilog IEEE 1364-2005 standard
module reset_masking (
    input wire [3:0] reset_vector,
    input wire [3:0] qualification_mask,
    output wire [3:0] masked_resets
);
    // Apply qualification mask to reset vector
    assign masked_resets = reset_vector & qualification_mask;
endmodule