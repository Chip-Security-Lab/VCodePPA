//SystemVerilog
module UART_MultiChannel #(
    parameter CHANNELS = 4,
    parameter CHAN_WIDTH = 2
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [CHAN_WIDTH-1:0] sel_chan,
    output reg  [CHANNELS-1:0] txd_bus,
    input  wire [CHANNELS-1:0] rxd_bus,
    input  wire [7:0] tx_data,
    output reg  [7:0] rx_data,
    input  wire cycle_start
);

    // Stage 1: Input Latch & Control
    reg [CHAN_WIDTH-1:0] time_slot_stage1;
    reg [CHANNELS-1:0]   chan_enable_stage1;
    reg [CHANNELS-1:0]   txd_bus_stage1;
    reg [7:0]            rx_data_stage1;
    reg [7:0]            tx_shift_stage1;
    reg [15:0]           current_baud_stage1;
    reg [CHAN_WIDTH-1:0] sel_chan_stage1;
    reg                  cycle_start_stage1;
    reg [7:0]            tx_data_stage1;
    reg [CHANNELS-1:0]   rxd_bus_stage1;
    reg                  valid_stage1;
    reg                  flush_stage1;

    // Stage 2: TX/RX Data Mux, Baudrate, Shift
    reg [CHAN_WIDTH-1:0] time_slot_stage2;
    reg [CHANNELS-1:0]   txd_bus_stage2;
    reg [7:0]            rx_data_stage2;
    reg [CHAN_WIDTH-1:0] sel_chan_stage2;
    reg                  cycle_start_stage2;
    reg [7:0]            tx_data_stage2;
    reg [CHANNELS-1:0]   rxd_bus_stage2;
    reg [7:0]            tx_shift_stage2;
    reg [15:0]           current_baud_stage2;
    reg                  valid_stage2;
    reg                  flush_stage2;

    // Stage 3: Output Registers
    reg [CHANNELS-1:0]   txd_bus_stage3;
    reg [7:0]            rx_data_stage3;
    reg                  valid_stage3;
    reg                  flush_stage3;

    // Channel memories and configuration
    reg [15:0] baud_table [0:CHANNELS-1];
    reg [7:0] mux_tx_data [0:CHANNELS-1];
    reg [7:0] mux_rx_data [0:CHANNELS-1];

    // Internal Time Slot
    reg [CHAN_WIDTH-1:0] time_slot_internal;
    reg [CHANNELS-1:0]   chan_enable_internal;

    integer i;

    // Pipeline Stage 1: Input Latch & Control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            time_slot_stage1      <= 0;
            chan_enable_stage1    <= 0;
            txd_bus_stage1        <= {CHANNELS{1'b1}};
            rx_data_stage1        <= 0;
            tx_shift_stage1       <= 0;
            current_baud_stage1   <= 0;
            sel_chan_stage1       <= 0;
            cycle_start_stage1    <= 0;
            tx_data_stage1        <= 0;
            rxd_bus_stage1        <= 0;
            valid_stage1          <= 1'b0;
            flush_stage1          <= 1'b1;
            time_slot_internal    <= 0;
            chan_enable_internal  <= 0;
            for (i = 0; i < CHANNELS; i = i + 1) begin
                mux_tx_data[i] <= 8'd0;
                mux_rx_data[i] <= 8'd0;
                baud_table[i]  <= 16'd0;
            end
        end else begin
            // Latch inputs
            sel_chan_stage1    <= sel_chan;
            tx_data_stage1     <= tx_data;
            rxd_bus_stage1     <= rxd_bus;
            cycle_start_stage1 <= cycle_start;
            valid_stage1       <= 1'b1;
            flush_stage1       <= 1'b0;

            // Save TX data to selected channel
            mux_tx_data[sel_chan] <= tx_data;

            // Output RX data from selected channel
            rx_data_stage1 <= mux_rx_data[sel_chan];

            // Time Slot Logic
            if (cycle_start) begin
                time_slot_internal <= (time_slot_internal == CHANNELS-1) ? 0 : time_slot_internal + 1;
                txd_bus_stage1 <= {CHANNELS{1'b1}};
                txd_bus_stage1[time_slot_internal] <= mux_tx_data[time_slot_internal][0];
            end else begin
                txd_bus_stage1 <= {CHANNELS{1'b1}};
            end

            // RX Data Processing
            for (i = 0; i < CHANNELS; i = i + 1) begin
                if (rxd_bus[i] == 1'b0) begin
                    mux_rx_data[i] <= {mux_rx_data[i][6:0], rxd_bus[i]};
                end
            end
            time_slot_stage1 <= time_slot_internal;
            chan_enable_stage1 <= chan_enable_internal;

            // Pipeline control
            if (flush_stage1)
                valid_stage1 <= 1'b0;
        end
    end

    // Pipeline Stage 2: Data Mux, Baudrate, Shift
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            time_slot_stage2    <= 0;
            txd_bus_stage2      <= {CHANNELS{1'b1}};
            rx_data_stage2      <= 0;
            sel_chan_stage2     <= 0;
            cycle_start_stage2  <= 0;
            tx_data_stage2      <= 0;
            rxd_bus_stage2      <= 0;
            tx_shift_stage2     <= 0;
            current_baud_stage2 <= 0;
            valid_stage2        <= 1'b0;
            flush_stage2        <= 1'b1;
        end else begin
            time_slot_stage2    <= time_slot_stage1;
            txd_bus_stage2      <= txd_bus_stage1;
            rx_data_stage2      <= rx_data_stage1;
            sel_chan_stage2     <= sel_chan_stage1;
            cycle_start_stage2  <= cycle_start_stage1;
            tx_data_stage2      <= tx_data_stage1;
            rxd_bus_stage2      <= rxd_bus_stage1;
            valid_stage2        <= valid_stage1;
            flush_stage2        <= flush_stage1;

            // Baudrate/Shift logic (combinational in original, now pipelined)
            current_baud_stage2 <= baud_table[sel_chan_stage1];
            tx_shift_stage2     <= mux_tx_data[sel_chan_stage1];
        end
    end

    // Pipeline Stage 3: Output Registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            txd_bus_stage3   <= {CHANNELS{1'b1}};
            rx_data_stage3   <= 0;
            valid_stage3     <= 1'b0;
            flush_stage3     <= 1'b1;
        end else begin
            txd_bus_stage3   <= txd_bus_stage2;
            rx_data_stage3   <= rx_data_stage2;
            valid_stage3     <= valid_stage2;
            flush_stage3     <= flush_stage2;
        end
    end

    // Output Assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            txd_bus <= {CHANNELS{1'b1}};
            rx_data <= 8'd0;
        end else if (valid_stage3 && !flush_stage3) begin
            txd_bus <= txd_bus_stage3;
            rx_data <= rx_data_stage3;
        end
    end

endmodule