//SystemVerilog
module GatedDiv(
    input clk, en,
    input [15:0] x, y,
    output reg [15:0] q
);
    always @(posedge clk) begin
        if(en) begin
            case (y)
                16'h0000: q <= 16'hFFFF; // Handle division by zero
                default: q <= x / y;     // Perform division
            endcase
        end
    end
endmodule