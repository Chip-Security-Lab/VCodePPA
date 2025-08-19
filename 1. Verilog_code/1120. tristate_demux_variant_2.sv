//SystemVerilog
module tristate_demux (
    input wire data,                     // Input data
    input wire [1:0] select,             // Selection control
    input wire output_enable,            // Output enable
    output wire [3:0] demux_bus          // Tristate output bus
);

wire select_is_0;
wire select_is_1;
wire select_is_2;
wire select_is_3;
wire valid_select;
wire enable_output;

assign select_is_0 = (select == 2'b00);
assign select_is_1 = (select == 2'b01);
assign select_is_2 = (select == 2'b10);
assign select_is_3 = (select == 2'b11);
assign valid_select = select_is_0 | select_is_1 | select_is_2 | select_is_3;
assign enable_output = output_enable & valid_select;

assign demux_bus[0] = (enable_output & select_is_0) ? data : 1'bz;
assign demux_bus[1] = (enable_output & select_is_1) ? data : 1'bz;
assign demux_bus[2] = (enable_output & select_is_2) ? data : 1'bz;
assign demux_bus[3] = (enable_output & select_is_3) ? data : 1'bz;

endmodule