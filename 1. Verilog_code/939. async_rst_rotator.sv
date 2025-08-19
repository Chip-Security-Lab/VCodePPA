module async_rst_rotator (
    input clk, arst, en,
    input [7:0] data_in,
    input [2:0] shift,
    output reg [7:0] data_out
);
always @(posedge clk or posedge arst) begin
    if (arst) data_out <= 0;
    else if (en) data_out <= (data_in << shift) | (data_in >> (8 - shift));
end
endmodule