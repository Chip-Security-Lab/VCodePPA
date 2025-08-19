//SystemVerilog
module dynamic_mask #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] mask_pattern,
    input mask_en,
    output reg [WIDTH-1:0] data_out
);

wire [WIDTH-1:0] mask_complement;
wire [WIDTH-1:0] masked_data;

assign mask_complement = ~mask_pattern + 1'b1;
assign masked_data = data_in + mask_complement;

always @(*) begin
    if (mask_en) begin
        data_out = masked_data;
    end
    else begin
        data_out = data_in;
    end
end

endmodule