//SystemVerilog
// Hierarchical UART Variable Width Module (Modularized & Optimized)

// -----------------------------------------------------------------------------
// Top-Level UART Variable Width Module
// Instantiates and connects functional submodules for modular design
// -----------------------------------------------------------------------------
module UART_VariableWidth #(
    parameter MAX_WIDTH = 9
)(
    input  wire [3:0]              data_width,      // Configurable: 5-9 bits
    input  wire [7:0]              rx_data,
    output wire [MAX_WIDTH-1:0]    rx_extended,
    input  wire [MAX_WIDTH-1:0]    tx_truncated,
    output wire [1:0]              stop_bits
);

    // Internal signals
    wire [MAX_WIDTH-1:0] width_aligned_data;
    wire                 is_nine_bit_mode;

    // Data Alignment and Mode Detection Submodule
    uart_data_align #(
        .MAX_WIDTH(MAX_WIDTH)
    ) u_data_align (
        .data_width         (data_width),
        .rx_data            (rx_data),
        .aligned_data       (width_aligned_data),
        .nine_bit_mode      (is_nine_bit_mode)
    );

    // Receive Data Extension Submodule
    uart_rx_extender #(
        .MAX_WIDTH(MAX_WIDTH)
    ) u_rx_extender (
        .aligned_data       (width_aligned_data),
        .tx_truncated       (tx_truncated),
        .nine_bit_mode      (is_nine_bit_mode),
        .rx_extended        (rx_extended)
    );

    // Stop Bits Generation Submodule
    uart_stop_bit_ctrl u_stop_bit_ctrl (
        .data_width         (data_width),
        .stop_bits          (stop_bits)
    );

endmodule

// -----------------------------------------------------------------------------
// Data Alignment & Mode Detection Module
// Aligns rx_data to MAX_WIDTH based on data_width and detects 9-bit mode
// -----------------------------------------------------------------------------
module uart_data_align #(
    parameter MAX_WIDTH = 9
)(
    input  wire [3:0]              data_width,
    input  wire [7:0]              rx_data,
    output reg  [MAX_WIDTH-1:0]    aligned_data,
    output reg                     nine_bit_mode
);
    // Function: Aligns rx_data to MAX_WIDTH bits, sets flag for 9-bit mode
    always @(*) begin
        nine_bit_mode = 1'b0;
        case (data_width)
            4'd5: aligned_data = {4'b0, rx_data[4:0]};
            4'd6: aligned_data = {3'b0, rx_data[5:0]};
            4'd7: aligned_data = {2'b0, rx_data[6:0]};
            4'd8: aligned_data = {1'b0, rx_data[7:0]};
            4'd9: begin
                aligned_data = {MAX_WIDTH{1'b0}};
                nine_bit_mode = 1'b1;
            end
            default: aligned_data = {1'b0, rx_data};
        endcase
    end
endmodule

// -----------------------------------------------------------------------------
// Receive Data Extension Module
// Selects between aligned rx_data and tx_truncated for 9-bit mode
// -----------------------------------------------------------------------------
module uart_rx_extender #(
    parameter MAX_WIDTH = 9
)(
    input  wire [MAX_WIDTH-1:0]    aligned_data,
    input  wire [MAX_WIDTH-1:0]    tx_truncated,
    input  wire                    nine_bit_mode,
    output reg  [MAX_WIDTH-1:0]    rx_extended
);
    // Function: For 9-bit data width, pass tx_truncated; else, use aligned_data
    always @(*) begin
        if (nine_bit_mode)
            rx_extended = tx_truncated;
        else
            rx_extended = aligned_data;
    end
endmodule

// -----------------------------------------------------------------------------
// Stop Bits Control Module
// Generates stop bit count based on configured data width
// -----------------------------------------------------------------------------
module uart_stop_bit_ctrl (
    input  wire [3:0]  data_width,
    output wire [1:0]  stop_bits
);
    // Function: Output 2 stop bits if data_width > 8, else 1
    assign stop_bits = (data_width > 4'd8) ? 2'd2 : 2'd1;
endmodule