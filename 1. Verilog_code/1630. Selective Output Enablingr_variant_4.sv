//SystemVerilog
module selective_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16,
    parameter ENABLE_MASK = 16'hFFFF
)(
    input [ADDR_WIDTH-1:0] addr,
    input enable,
    output [OUT_WIDTH-1:0] select
);
    // Pre-computed lookup table for 4-bit to 16-bit one-hot encoding
    reg [OUT_WIDTH-1:0] lut [0:15];
    
    // Optimized initialization using a more compact representation
    initial begin
        lut[0] = 16'h0001;
        lut[1] = 16'h0002;
        lut[2] = 16'h0004;
        lut[3] = 16'h0008;
        lut[4] = 16'h0010;
        lut[5] = 16'h0020;
        lut[6] = 16'h0040;
        lut[7] = 16'h0080;
        lut[8] = 16'h0100;
        lut[9] = 16'h0200;
        lut[10] = 16'h0400;
        lut[11] = 16'h0800;
        lut[12] = 16'h1000;
        lut[13] = 16'h2000;
        lut[14] = 16'h4000;
        lut[15] = 16'h8000;
    end
    
    // Direct lookup with enable control
    wire [OUT_WIDTH-1:0] lut_output;
    assign lut_output = lut[addr];
    
    // Final output with enable and mask
    assign select = enable ? (lut_output & ENABLE_MASK) : {OUT_WIDTH{1'b0}};
endmodule