//SystemVerilog
module GatedDiv(
    input clk, en,
    input [15:0] x, y,
    output reg [15:0] q
);
    reg [15:0] div_result;
    reg [15:0] default_result;

    always @* begin
        if (y != 0)
            div_result = x / y;
        else
            div_result = 16'hFFFF;
    end

    always @(posedge clk) begin
        if (en)
            q <= div_result;
    end
endmodule