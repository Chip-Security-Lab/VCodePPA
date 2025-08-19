//SystemVerilog
// Top-level module: Hierarchical 1-to-8 Synchronous Demux with Buffered High Fanout Path
module sync_1to8_demux (
    input wire clock,                   // System clock
    input wire data,                    // Input data
    input wire [2:0] address,           // 3-bit address
    output wire [7:0] outputs           // 8 registered outputs
);

    wire [7:0] demux_out_internal;
    wire [7:0] demux_out_buf;

    // Instantiate the 1-to-8 decoder submodule
    demux1to8_decoder u_decoder (
        .data_in(data),
        .address_in(address),
        .demux_out(demux_out_internal)
    );

    // Buffer register for high fanout signal demux_out
    demux1to8_buffer u_buffer (
        .clk(clock),
        .din(demux_out_internal),
        .dout(demux_out_buf)
    );

    // Instantiate the 8-bit output register submodule
    demux1to8_register u_register (
        .clk(clock),
        .din(demux_out_buf),
        .dout(outputs)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: demux1to8_decoder
// Function: Decodes 3-bit address and data to 8-bit one-hot output
// -----------------------------------------------------------------------------
module demux1to8_decoder (
    input  wire        data_in,         // Input data
    input  wire [2:0]  address_in,      // 3-bit address
    output wire [7:0]  demux_out        // 8-bit one-hot demux output
);
    assign demux_out = (data_in) ? (8'b1 << address_in) : 8'b0;
endmodule

// -----------------------------------------------------------------------------
// Submodule: demux1to8_buffer
// Function: Buffers the high fanout demux_out signal to reduce delay
// -----------------------------------------------------------------------------
module demux1to8_buffer (
    input  wire        clk,             // System clock
    input  wire [7:0]  din,             // Input data to buffer
    output reg  [7:0]  dout             // Buffered output
);
    always @(posedge clk) begin
        dout <= din;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: demux1to8_register
// Function: Registers the 8-bit demux output, clearing outputs on every clock
// -----------------------------------------------------------------------------
module demux1to8_register (
    input  wire        clk,             // System clock
    input  wire [7:0]  din,             // Demuxed input data
    output reg  [7:0]  dout             // Registered output
);
    always @(posedge clk) begin
        dout <= din;
    end
endmodule