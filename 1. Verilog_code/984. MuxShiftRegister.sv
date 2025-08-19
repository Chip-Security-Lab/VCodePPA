module MuxShiftRegister #(parameter WIDTH=8) (
    input clk, sel,
    input [1:0] serial_in,
    output reg [WIDTH-1:0] data_out
);
always @(posedge clk) begin
    data_out <= {data_out[WIDTH-2:0], serial_in[sel]};
end
endmodule