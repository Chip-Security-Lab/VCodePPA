//SystemVerilog
module MuxShiftRegister #(parameter WIDTH=8) (
    input clk,
    input sel,
    input [1:0] serial_in,
    output reg [WIDTH-1:0] data_out
);

wire selected_serial_in;
assign selected_serial_in = serial_in[sel];

reg [WIDTH-2:0] shift_reg;

always @(posedge clk) begin
    shift_reg <= data_out[WIDTH-2:0];
    data_out <= {shift_reg, selected_serial_in};
end

endmodule