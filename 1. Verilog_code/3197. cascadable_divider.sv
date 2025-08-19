module cascadable_divider (
    input clk_in,
    input cascade_en,
    output reg clk_out,
    output cascade_out
);
reg [7:0] counter;

always @(posedge clk_in) begin
    if (counter == 8'd9) begin
        counter <= 0;
        clk_out <= ~clk_out;
    end else begin
        counter <= counter + 1;
    end
end

assign cascade_out = (counter == 8'd9) ? 1'b1 : 1'b0;
endmodule
