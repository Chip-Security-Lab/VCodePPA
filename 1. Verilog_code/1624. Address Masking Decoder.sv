module mask_decoder (
    input [7:0] addr,
    input [7:0] mask,
    output reg [3:0] sel
);
    always @(*) begin
        sel = 4'b0000;
        case (addr & mask)
            8'h00: sel = 4'b0001;
            8'h10: sel = 4'b0010;
            8'h20: sel = 4'b0100;
            8'h30: sel = 4'b1000;
            default: sel = 4'b0000;
        endcase
    end
endmodule