module shift_div #(parameter PATTERN=8'b1010_1100) (
    input clk, rst,
    output wire clk_out
);
reg [7:0] shift_reg;
assign clk_out = shift_reg[7];

always @(posedge clk) begin
    if(rst) shift_reg <= PATTERN;
    else shift_reg <= {shift_reg[6:0], shift_reg[7]};
end
endmodule
