module dynamic_divider #(
    parameter CTR_WIDTH = 8
)(
    input clk,
    input [CTR_WIDTH-1:0] div_value,
    input load,
    output reg clk_div
);
reg [CTR_WIDTH-1:0] counter;
reg [CTR_WIDTH-1:0] current_div;

always @(posedge clk) begin
    if (load) current_div <= div_value;
end

always @(posedge clk) begin
    if (counter >= current_div-1) begin
        counter <= 0;
        clk_div <= ~clk_div;
    end else begin
        counter <= counter + 1;
    end
end
endmodule
