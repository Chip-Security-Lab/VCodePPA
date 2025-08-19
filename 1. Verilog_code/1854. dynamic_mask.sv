module dynamic_mask #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] mask_pattern,
    input mask_en,
    output reg [WIDTH-1:0] data_out
);
always @(*) begin
    data_out = mask_en ? (data_in & mask_pattern) : data_in;
end
endmodule