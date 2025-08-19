module parametric_crc #(
    parameter WIDTH = 8,
    parameter POLY = 8'h9B,
    parameter INIT = {WIDTH{1'b1}}
)(
    input clk, en,
    input [WIDTH-1:0] data,
    output reg [WIDTH-1:0] crc
);
always @(posedge clk) begin
    if (en) begin
        crc <= (crc << 1) ^ (data ^ (crc[WIDTH-1] ? POLY : 0));
    end else begin
        crc <= INIT;
    end
end
endmodule