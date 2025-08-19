//SystemVerilog
// Top-level UART_VariableWidth with hierarchical submodules

module UART_VariableWidth #(
    parameter MAX_WIDTH = 9
)(
    input  wire [3:0]               data_width,    // 5-9 bits configurable
    input  wire [7:0]               rx_data,
    output wire [MAX_WIDTH-1:0]     rx_extended,
    input  wire [MAX_WIDTH-1:0]     tx_truncated,
    output wire [1:0]               stop_bits
);

    // Internal signals
    wire [7:0]                      rx_core;
    wire [MAX_WIDTH-1:0]            tx_core;
    wire [7:0]                      zero_ext_8;
    wire [7:0]                      difference;
    wire                            cla_borrow_out;
    wire [MAX_WIDTH-1:0]            rx_extended_int;

    // Receive data path
    assign rx_core    = rx_data;
    assign tx_core    = tx_truncated;
    assign zero_ext_8 = 8'b0;

    // Subtractor unit: 8-bit carry lookahead borrow subtractor
    CLA_Subtractor8 u_cla_subtractor8 (
        .minuend    (rx_core),
        .subtrahend (zero_ext_8),
        .borrow_in  (1'b0),
        .difference (difference),
        .borrow_out (cla_borrow_out)
    );

    // RX Data Width Selector
    UART_RX_DataWidthSelector #(
        .MAX_WIDTH (MAX_WIDTH)
    ) u_rx_datawidth_selector (
        .data_width     (data_width),
        .difference_8b  (difference),
        .tx_truncated   (tx_truncated),
        .rx_extended    (rx_extended_int)
    );

    assign rx_extended = rx_extended_int;

    // Stop Bit Generator
    UART_StopBitGenerator u_stop_bit_generator (
        .data_width (data_width),
        .stop_bits  (stop_bits)
    );

endmodule


//------------------------------------------------------------------------------
// 8-bit Carry Lookahead Borrow Subtractor
//-----------------------------------------------------------------------------
module CLA_Subtractor8 (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    input  wire       borrow_in,
    output wire [7:0] difference,
    output wire       borrow_out
);
    wire [7:0] generate_borrow;
    wire [7:0] propagate_borrow;
    wire [8:0] borrow_chain;

    assign borrow_chain[0] = borrow_in;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : bit_borrow
            assign generate_borrow[i]  = (~minuend[i]) & subtrahend[i];
            assign propagate_borrow[i] = (~minuend[i]) | subtrahend[i];
            assign borrow_chain[i+1]   = generate_borrow[i] | (propagate_borrow[i] & borrow_chain[i]);
            assign difference[i]       = minuend[i] ^ subtrahend[i] ^ borrow_chain[i];
        end
    endgenerate

    assign borrow_out = borrow_chain[8];
endmodule


//------------------------------------------------------------------------------
// UART RX Data Width Selector
//   - Selects/extends rx data based on data width configuration
//-----------------------------------------------------------------------------
module UART_RX_DataWidthSelector #(
    parameter MAX_WIDTH = 9
)(
    input  wire [3:0]               data_width,
    input  wire [7:0]               difference_8b,
    input  wire [MAX_WIDTH-1:0]     tx_truncated,
    output reg  [MAX_WIDTH-1:0]     rx_extended
);
    always @(*) begin
        case (data_width)
            4'd5: rx_extended = {4'b0, difference_8b[4:0]};
            4'd6: rx_extended = {3'b0, difference_8b[5:0]};
            4'd7: rx_extended = {2'b0, difference_8b[6:0]};
            4'd8: rx_extended = {1'b0, difference_8b[7:0]};
            4'd9: rx_extended = tx_truncated; // Directly use 9-bit data
            default: rx_extended = {1'b0, difference_8b}; // Default 8-bit
        endcase
    end
endmodule


//------------------------------------------------------------------------------
// UART Stop Bit Generator
//   - Generates stop bit count based on data width
//-----------------------------------------------------------------------------
module UART_StopBitGenerator (
    input  wire [3:0] data_width,
    output wire [1:0] stop_bits
);
    assign stop_bits = (data_width > 8) ? 2'd2 : 2'd1;
endmodule