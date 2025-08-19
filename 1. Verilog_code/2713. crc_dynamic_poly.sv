module crc_dynamic_poly #(parameter WIDTH=16)(
    input clk, load_poly,
    input [WIDTH-1:0] data_in, new_poly,
    output reg [WIDTH-1:0] crc
);
reg [WIDTH-1:0] poly_reg;

always @(posedge clk) begin
    if (load_poly) poly_reg <= new_poly;
    else crc <= (crc << 1) ^ (data_in ^ (crc[WIDTH-1] ? poly_reg : 0));
end
endmodule
