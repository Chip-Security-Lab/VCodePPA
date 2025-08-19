module shift_preload #(parameter WIDTH=8) (
    input clk, load,
    input [WIDTH-1:0] load_data,
    output reg [WIDTH-1:0] sr
);
always @(posedge clk) begin
    sr <= load ? load_data : {sr[WIDTH-2:0], 1'b0};
end
endmodule
