//SystemVerilog
// Top-level module: Hierarchical MuxShiftRegister
module MuxShiftRegister #(parameter WIDTH=8) (
    input clk,
    input sel,
    input [1:0] serial_in,
    output [WIDTH-1:0] data_out
);

    // Internal signals for interconnection
    wire serial_muxed;
    wire [WIDTH-2:0] shift_reg;

    // Serial input multiplexer
    SerialInputMux serial_input_mux_inst (
        .clk(clk),
        .sel(sel),
        .serial_in(serial_in),
        .serial_muxed(serial_muxed)
    );

    // Shift register logic
    ShiftRegister #(.WIDTH(WIDTH)) shift_register_inst (
        .clk(clk),
        .serial_in(serial_muxed),
        .shift_reg(shift_reg)
    );

    // Output concatenation
    assign data_out = {shift_reg, serial_muxed};

endmodule

// -----------------------------------------------------------------------------
// SerialInputMux
// 2:1 multiplexer for serial input selection
// -----------------------------------------------------------------------------
module SerialInputMux (
    input clk,
    input sel,
    input [1:0] serial_in,
    output reg serial_muxed
);
    always @(posedge clk) begin
        serial_muxed <= serial_in[sel];
    end
endmodule

// -----------------------------------------------------------------------------
// ShiftRegister
// Parameterized shift register (WIDTH-1 bits)
// -----------------------------------------------------------------------------
module ShiftRegister #(parameter WIDTH=8) (
    input clk,
    input serial_in,
    output reg [WIDTH-2:0] shift_reg
);
    always @(posedge clk) begin
        shift_reg <= {shift_reg[WIDTH-3:0], serial_in};
    end
endmodule

// -----------------------------------------------------------------------------
// Subtract2Bit
// 2-bit subtractor using two's complement adder logic
// Standalone combinational module for reuse
// -----------------------------------------------------------------------------
module Subtract2Bit (
    input [1:0] a,
    input [1:0] b,
    output [1:0] diff
);
    wire [1:0] b_complement;
    assign b_complement = ~b;
    assign diff = a + b_complement + 2'b01;
endmodule