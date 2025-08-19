module DynamicWidthShifter #(parameter MAX_WIDTH=16) (
    input clk,
    input [4:0] current_width,
    input serial_in,
    output reg serial_out
);
reg [MAX_WIDTH-1:0] buffer;
always @(posedge clk) begin
    buffer <= {buffer[MAX_WIDTH-2:0], serial_in};
    serial_out <= buffer[current_width-1];
end
endmodule