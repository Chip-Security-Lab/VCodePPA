//SystemVerilog
// Top-level UART Variable Width Module (Hierarchical, Layered Structure)
module UART_VariableWidth #(
    parameter MAX_WIDTH = 9
)(
    input  wire [3:0]              data_width,         // Configurable width: 5-9 bits
    input  wire [7:0]              rx_data,            // 8-bit received data
    output wire [MAX_WIDTH-1:0]    rx_extended,        // Extended received data
    input  wire [MAX_WIDTH-1:0]    tx_truncated,       // Truncated transmit data
    output wire [1:0]              stop_bits           // Number of stop bits
);

    // Internal signals for submodule interconnection
    wire [7:0]               rx_core_data;
    wire [MAX_WIDTH-1:0]     tx_core_data;
    wire [MAX_WIDTH-1:0]     rx_extended_internal;
    wire [1:0]               stop_bits_internal;

    // Receive Core: Handles RX data preparation
    UART_ReceiveCore u_receive_core (
        .rx_data_in         (rx_data),
        .rx_core_out        (rx_core_data)
    );

    // Transmit Core: Handles TX data preparation
    UART_TransmitCore #(
        .MAX_WIDTH(MAX_WIDTH)
    ) u_transmit_core (
        .tx_truncated_in    (tx_truncated),
        .tx_core_out        (tx_core_data)
    );

    // Data Width Adapter: Adjusts data width for RX
    UART_DataWidthAdapter #(
        .MAX_WIDTH(MAX_WIDTH)
    ) u_datawidth_adapter (
        .data_width         (data_width),
        .rx_core            (rx_core_data),
        .tx_truncated       (tx_core_data),
        .rx_extended        (rx_extended_internal)
    );

    // Stop Bit Generator: Determines stop bits based on data width
    UART_StopBitGen u_stopbit_gen (
        .data_width         (data_width),
        .stop_bits          (stop_bits_internal)
    );

    // Output assignments
    assign rx_extended = rx_extended_internal;
    assign stop_bits   = stop_bits_internal;

endmodule

// -----------------------------------------------------------------------------
// Submodule: UART_ReceiveCore
// Description: Handles received data input and provides RX core data
// -----------------------------------------------------------------------------
module UART_ReceiveCore (
    input  wire [7:0]  rx_data_in,
    output wire [7:0]  rx_core_out
);
    assign rx_core_out = rx_data_in;
endmodule

// -----------------------------------------------------------------------------
// Submodule: UART_TransmitCore
// Description: Handles transmit data input and provides TX core data
// -----------------------------------------------------------------------------
module UART_TransmitCore #(
    parameter MAX_WIDTH = 9
)(
    input  wire [MAX_WIDTH-1:0]   tx_truncated_in,
    output wire [MAX_WIDTH-1:0]   tx_core_out
);
    assign tx_core_out = tx_truncated_in;
endmodule

// -----------------------------------------------------------------------------
// Submodule: UART_DataWidthAdapter
// Description: Adapts received and transmitted data widths based on configuration
// -----------------------------------------------------------------------------
module UART_DataWidthAdapter #(
    parameter MAX_WIDTH = 9
)(
    input  wire [3:0]              data_width,     // Configurable width: 5-9 bits
    input  wire [7:0]              rx_core,        // 8-bit received data core
    input  wire [MAX_WIDTH-1:0]    tx_truncated,   // Truncated transmit data
    output reg  [MAX_WIDTH-1:0]    rx_extended     // Extended received data
);
    always @(*) begin
        case(data_width)
            4'd5: rx_extended = {4'b0, rx_core[4:0]};
            4'd6: rx_extended = {3'b0, rx_core[5:0]};
            4'd7: rx_extended = {2'b0, rx_core[6:0]};
            4'd8: rx_extended = {1'b0, rx_core[7:0]};
            4'd9: rx_extended = tx_truncated; // Directly pass 9-bit data
            default: rx_extended = {1'b0, rx_core}; // Default to 8 bits
        endcase
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: UART_StopBitGen
// Description: Dynamically generates stop bits based on data width configuration
// -----------------------------------------------------------------------------
module UART_StopBitGen (
    input  wire [3:0]  data_width,     // Configurable width: 5-9 bits
    output wire [1:0]  stop_bits       // Number of stop bits
);
    assign stop_bits = (data_width > 8) ? 2'd2 : 2'd1;
endmodule