//SystemVerilog
// Top-level module
module decoder_async #(
    parameter AW = 4,
    parameter DW = 16
) (
    input  [AW-1:0] addr,
    output [DW-1:0] decoded
);
    reg [DW-1:0] lut_based_decoder [0:DW-1];
    reg [DW-1:0] decoder_result;
    wire addr_valid;
    
    // Initialize lookup table for decoder
    integer i;
    initial begin
        for (i = 0; i < DW; i = i + 1) begin
            lut_based_decoder[i] = (1'b1 << i);
        end
    end
    
    // Address validator sub-module
    addr_validator #(
        .AW(AW),
        .DW(DW)
    ) u_addr_validator (
        .addr(addr),
        .addr_valid(addr_valid)
    );
    
    // LUT-based decoder logic
    always @(*) begin
        if (addr < DW)
            decoder_result = lut_based_decoder[addr];
        else
            decoder_result = {DW{1'b0}};
    end
    
    // Final output assignment
    assign decoded = addr_valid ? decoder_result : {DW{1'b0}};
    
endmodule

// Sub-module to validate if address is within valid range
module addr_validator #(
    parameter AW = 4,
    parameter DW = 16
) (
    input  [AW-1:0] addr,
    output addr_valid
);
    assign addr_valid = (addr < DW);
endmodule