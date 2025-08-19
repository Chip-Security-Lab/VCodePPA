module GrayCodeShifter #(parameter WIDTH=8) (
    input clk, en,
    output reg [WIDTH-1:0] gray_out
);
reg [WIDTH-1:0] binary_reg;
always @(posedge clk) begin
    if (en) begin
        binary_reg <= {binary_reg[WIDTH-2:0], ~^binary_reg};
        gray_out <= binary_reg ^ {1'b0, binary_reg[WIDTH-1:1]};
    end
end
endmodule