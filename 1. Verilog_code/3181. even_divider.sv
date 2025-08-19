module even_divider #(
    parameter DIV_WIDTH = 8,
    parameter DIV_VALUE = 10
)(
    input clk_in,
    input rst_n,
    output reg clk_out
);
reg [DIV_WIDTH-1:0] counter;

always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 0;
        clk_out <= 0;
    end else begin
        counter <= (counter == DIV_VALUE-1) ? 0 : counter + 1;
        clk_out <= (counter < (DIV_VALUE>>1)) ? 1'b0 : 1'b1;
    end
end
endmodule
