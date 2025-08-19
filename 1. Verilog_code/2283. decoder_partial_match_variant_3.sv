//SystemVerilog
// Top-level module
module decoder_partial_match #(
    parameter MASK = 4'hF
) (
    input wire [3:0] addr_in,
    output wire [7:0] device_sel
);
    // Internal signals
    wire addr_match;
    
    // Instantiate address comparison module
    address_comparator #(
        .MASK(MASK),
        .TARGET_ADDR(4'hA)
    ) addr_comp_inst (
        .addr_in(addr_in),
        .match_out(addr_match)
    );
    
    // Instantiate output decoder module with parameterized width
    output_decoder #(
        .OUT_WIDTH(8)
    ) out_dec_inst (
        .match_in(addr_match),
        .device_sel(device_sel)
    );
    
endmodule

// Address comparison module with configurable mask and target
module address_comparator #(
    parameter MASK = 4'hF,
    parameter TARGET_ADDR = 4'h0,
    parameter ADDR_WIDTH = 4
) (
    input wire [ADDR_WIDTH-1:0] addr_in,
    output wire match_out
);
    // Masked address comparison logic
    wire [ADDR_WIDTH-1:0] masked_addr;
    
    // Apply mask first to reduce switching activity
    assign masked_addr = addr_in & MASK;
    
    // Compare masked address with target
    assign match_out = (masked_addr == (TARGET_ADDR & MASK));
    
endmodule

// Parameterized output decoder module
module output_decoder #(
    parameter OUT_WIDTH = 8,
    parameter ACTIVE_BIT = 0
) (
    input wire match_in,
    output wire [OUT_WIDTH-1:0] device_sel
);
    // Generate device select signal based on match
    // Set only the specified bit when matched
    generate
        genvar i;
        for (i = 0; i < OUT_WIDTH; i = i + 1) begin : gen_output
            if (i == ACTIVE_BIT)
                assign device_sel[i] = match_in;
            else
                assign device_sel[i] = 1'b0;
        end
    endgenerate
    
endmodule