//SystemVerilog
module GatedDiv(
    input clk, en,
    input [15:0] x, y,
    output reg [15:0] q
);
    always @(posedge clk) begin
        if (en) begin
            if (y != 0) begin
                q <= x / y;
            end else begin
                q <= 16'hFFFF;
            end
        end
    end
endmodule