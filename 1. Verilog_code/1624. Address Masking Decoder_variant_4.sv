//SystemVerilog
module mask_decoder (
    input [7:0] addr,
    input [7:0] mask,
    output reg [3:0] sel
);
    // Internal signals for signed multiplication optimization
    reg [7:0] addr_signed;
    reg [7:0] mask_signed;
    reg [7:0] result;
    reg [7:0] partial_product;
    reg [7:0] shifted_addr;
    
    always @(*) begin
        // Initialize output
        sel = 4'b0000;
        
        // Convert inputs to signed representation
        addr_signed = addr;
        mask_signed = mask;
        
        // Optimized signed multiplication algorithm
        result = 8'h00;
        shifted_addr = addr_signed;
        
        // Booth's algorithm implementation for 8-bit signed multiplication
        for (integer i = 0; i < 8; i = i + 1) begin
            if (mask_signed[0]) begin
                partial_product = shifted_addr;
                result = result + partial_product;
            end
            shifted_addr = {shifted_addr[6:0], 1'b0}; // Shift left by 1
            mask_signed = {1'b0, mask_signed[7:1]};   // Shift right by 1
        end
        
        // Decode the result
        case (result)
            8'h00: sel = 4'b0001;
            8'h10: sel = 4'b0010;
            8'h20: sel = 4'b0100;
            8'h30: sel = 4'b1000;
            default: sel = 4'b0000;
        endcase
    end
endmodule