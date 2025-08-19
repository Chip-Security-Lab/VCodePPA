//SystemVerilog
module mask_decoder (
    input [7:0] addr,
    input [7:0] mask,
    output reg [3:0] sel
);
    // Signed multiplication optimization
    reg [7:0] addr_signed;
    reg [7:0] mask_signed;
    reg [7:0] result;
    
    // Convert inputs to signed representation
    always @(*) begin
        addr_signed = addr;
        mask_signed = mask;
        
        // Perform signed multiplication using Booth's algorithm
        result = 8'b0;
        for (integer i = 0; i < 8; i = i + 1) begin
            if (mask_signed[i]) begin
                result = result + (addr_signed << i);
            end
        end
    end
    
    // Decode result to select signal
    always @(*) begin
        sel = 4'b0000;
        case (result)
            8'h00: sel = 4'b0001;
            8'h10: sel = 4'b0010;
            8'h20: sel = 4'b0100;
            8'h30: sel = 4'b1000;
            default: sel = 4'b0000;
        endcase
    end
endmodule