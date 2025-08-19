module LUTDiv(input [3:0] x,y, output reg [7:0] q);
    always @(*) begin
        case({x,y})
            8'h00: q=8'hFF;
            8'h01: q=8'h00;
            // ...完整LUT内容
            default: q= (x << 4) / y; 
        endcase
    end
endmodule