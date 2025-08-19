//SystemVerilog
module UART_MultiChannel #(
    parameter CHANNELS = 4,
    parameter CHAN_WIDTH = 2
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [CHAN_WIDTH-1:0] sel_chan,
    output reg  [CHANNELS-1:0]  txd_bus,
    input  wire [CHANNELS-1:0]  rxd_bus,
    input  wire [7:0]           tx_data,
    output reg  [7:0]           rx_data,
    input  wire                 cycle_start
);

reg [CHAN_WIDTH-1:0] time_slot;
reg [CHANNELS-1:0] chan_enable;
reg [15:0] baud_table [0:CHANNELS-1];
reg [7:0] tx_shift_reg;
reg [15:0] current_baud_reg;

reg [7:0] mux_tx_data [0:CHANNELS-1];
reg [7:0] mux_rx_data [0:CHANNELS-1];

reg [7:0] mux_tx_data_buf [0:CHANNELS-1];
reg [7:0] mux_rx_data_buf [0:CHANNELS-1];
reg [CHAN_WIDTH-1:0] i_buf;

reg [7:0] mux_tx_data_buf_lvl2 [0:CHANNELS-1];
reg [7:0] mux_rx_data_buf_lvl2 [0:CHANNELS-1];
reg [CHAN_WIDTH-1:0] i_buf_lvl2;

integer i;

// Reset and registers initialization
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        time_slot <= 0;
        chan_enable <= 0;
        txd_bus <= {CHANNELS{1'b1}};
        rx_data <= 0;
        tx_shift_reg <= 0;
        current_baud_reg <= 0;
        for (i = 0; i < CHANNELS; i = i + 1) begin
            mux_tx_data[i] <= 8'd0;
            mux_rx_data[i] <= 8'd0;
            baud_table[i] <= 16'd0;
            mux_tx_data_buf[i] <= 8'd0;
            mux_rx_data_buf[i] <= 8'd0;
            mux_tx_data_buf_lvl2[i] <= 8'd0;
            mux_rx_data_buf_lvl2[i] <= 8'd0;
        end
        i_buf <= 0;
        i_buf_lvl2 <= 0;
    end
end

// Write tx_data to mux_tx_data
always @(posedge clk) begin
    if (rst_n) begin
        mux_tx_data[sel_chan] <= tx_data;
    end
end

// Buffer mux_tx_data and mux_rx_data to buf
always @(posedge clk) begin
    if (rst_n) begin
        for (i = 0; i < CHANNELS; i = i + 1) begin
            mux_tx_data_buf[i] <= mux_tx_data[i];
            mux_rx_data_buf[i] <= mux_rx_data[i];
        end
    end
end

// Buffer to level2
always @(posedge clk) begin
    if (rst_n) begin
        for (i = 0; i < CHANNELS; i = i + 1) begin
            mux_tx_data_buf_lvl2[i] <= mux_tx_data_buf[i];
            mux_rx_data_buf_lvl2[i] <= mux_rx_data_buf[i];
        end
    end
end

// Output rx_data from buffered mux_rx_data
always @(posedge clk) begin
    if (rst_n) begin
        rx_data <= mux_rx_data_buf_lvl2[sel_chan];
    end
end

// Time slot and txd_bus control
always @(posedge clk) begin
    if (rst_n) begin
        if (cycle_start) begin
            time_slot <= (time_slot == CHANNELS-1) ? 0 : time_slot + 1;
            txd_bus <= {CHANNELS{1'b1}};
            txd_bus[time_slot] <= tx_shift_reg[0];
        end
    end
end

// txd_bus reset on reset
always @(negedge rst_n) begin
    if (!rst_n) begin
        txd_bus <= {CHANNELS{1'b1}};
    end
end

// Buffer time_slot to i_buf
always @(posedge clk) begin
    if (rst_n) begin
        i_buf <= time_slot;
    end
end

// Buffer i_buf to i_buf_lvl2
always @(posedge clk) begin
    if (rst_n) begin
        i_buf_lvl2 <= i_buf;
    end
end

// Receive data shift register logic
always @(posedge clk) begin
    if (rst_n) begin
        for (i = 0; i < CHANNELS; i = i + 1) begin
            if (rxd_bus[i] == 1'b0) begin
                mux_rx_data[i] <= {mux_rx_data[i][6:0], rxd_bus[i]};
            end
        end
    end
end

// Channel configuration combinational logic
always @(*) begin
    current_baud_reg = baud_table[sel_chan];
    tx_shift_reg = mux_tx_data_buf_lvl2[sel_chan];
end

endmodule