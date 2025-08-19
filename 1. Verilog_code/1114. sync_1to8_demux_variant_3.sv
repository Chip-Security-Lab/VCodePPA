//SystemVerilog

//-----------------------------------------------------------------------------
// Data Register Module
// Registers the input data and address on the rising edge of the clock
//-----------------------------------------------------------------------------
module data_register #(
    parameter ADDR_WIDTH = 3
)(
    input  wire                  clk,
    input  wire [ADDR_WIDTH-1:0] address_in,
    input  wire                  data_in,
    output reg  [ADDR_WIDTH-1:0] address_out,
    output reg                   data_out
);
    always @(posedge clk) begin
        address_out <= address_in;
        data_out    <= data_in;
    end
endmodule

//-----------------------------------------------------------------------------
// 1-to-8 Demultiplexer Module
// Takes registered data and address, outputs an 8-bit one-hot signal
//-----------------------------------------------------------------------------
module demux1to8 (
    input  wire [2:0] address,
    input  wire       data_in,
    output reg  [7:0] demux_out
);
    integer i;
    always @(*) begin
        demux_out = 8'b0;
        demux_out[address] = data_in;
    end
endmodule

//-----------------------------------------------------------------------------
// Output Register Module
// Registers the demuxed output on the rising edge of the clock
//-----------------------------------------------------------------------------
module output_register (
    input  wire       clk,
    input  wire [7:0] data_in,
    output reg  [7:0] data_out
);
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule

//-----------------------------------------------------------------------------
// Top-Level Synchronous 1-to-8 Demux Module
// Hierarchically integrates data registration, demux, and output registration
//-----------------------------------------------------------------------------
module sync_1to8_demux (
    input  wire       clock,      // System clock
    input  wire       data,       // Input data
    input  wire [2:0] address,    // 3-bit address
    output wire [7:0] outputs     // 8 registered outputs
);

    // Internal signals for registered address/data and demux output
    wire [2:0] address_reg;
    wire       data_reg;
    wire [7:0] demux_out;

    // Input data and address registration
    data_register #(
        .ADDR_WIDTH(3)
    ) u_data_register (
        .clk         (clock),
        .address_in  (address),
        .data_in     (data),
        .address_out (address_reg),
        .data_out    (data_reg)
    );

    // 1-to-8 demultiplexer logic
    demux1to8 u_demux1to8 (
        .address   (address_reg),
        .data_in   (data_reg),
        .demux_out (demux_out)
    );

    // Output register for one-hot output
    output_register u_output_register (
        .clk     (clock),
        .data_in (demux_out),
        .data_out(outputs)
    );

endmodule