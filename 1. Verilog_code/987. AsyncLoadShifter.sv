module AsyncLoadShifter #(parameter WIDTH=8) (
    input clk, async_load,
    input [WIDTH-1:0] load_data,
    output reg [WIDTH-1:0] data_reg
);
always @(posedge clk or posedge async_load) begin
    if (async_load) data_reg <= load_data;
    else data_reg <= {data_reg[WIDTH-2:0], 1'b0};
end
endmodule