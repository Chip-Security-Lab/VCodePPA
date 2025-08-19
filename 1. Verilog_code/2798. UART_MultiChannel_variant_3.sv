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

// Stage 1 Registers
reg [CHAN_WIDTH-1:0] time_slot_stage1;
reg [CHANNELS-1:0]   chan_enable_stage1;
reg [7:0]            tx_data_stage1;
reg [CHAN_WIDTH-1:0] sel_chan_stage1;
reg                  cycle_start_stage1;
reg [CHANNELS-1:0]   rxd_bus_stage1;

// Stage 2 Registers
reg [7:0] mux_tx_data [0:CHANNELS-1];
reg [7:0] mux_rx_data [0:CHANNELS-1];
reg [15:0] baud_table [0:CHANNELS-1];
reg [15:0] current_baud_stage2;
reg [7:0]  tx_shift_stage2;
reg [CHAN_WIDTH-1:0] time_slot_stage2;
reg [CHAN_WIDTH-1:0] sel_chan_stage2;
reg                  cycle_start_stage2;
reg [CHANNELS-1:0]   rxd_bus_stage2;

// Stage 3 Registers
reg [7:0] rx_data_stage3;
reg [7:0] tx_shift_stage3;
reg [15:0] current_baud_stage3;
reg [CHAN_WIDTH-1:0] time_slot_stage3;
reg                  cycle_start_stage3;

// Internal variable for for-loops
integer idx;

//================= Stage 1: Input Registers =================

// Pipeline: time_slot_stage1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        time_slot_stage1 <= 0;
    else if (cycle_start)
        time_slot_stage1 <= (time_slot_stage1 == (CHANNELS-1)) ? {CHAN_WIDTH{1'b0}} : time_slot_stage1 + 1'b1;
end

// Pipeline: chan_enable_stage1 (placeholder for future logic)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        chan_enable_stage1 <= {CHANNELS{1'b0}};
    else
        chan_enable_stage1 <= chan_enable_stage1;
end

// Pipeline: tx_data_stage1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        tx_data_stage1 <= 8'd0;
    else
        tx_data_stage1 <= tx_data;
end

// Pipeline: sel_chan_stage1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sel_chan_stage1 <= {CHAN_WIDTH{1'b0}};
    else
        sel_chan_stage1 <= sel_chan;
end

// Pipeline: cycle_start_stage1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cycle_start_stage1 <= 1'b0;
    else
        cycle_start_stage1 <= cycle_start;
end

// Pipeline: rxd_bus_stage1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rxd_bus_stage1 <= {CHANNELS{1'b0}};
    else
        rxd_bus_stage1 <= rxd_bus;
end

//================= Stage 2: Channel Buffers and Pipeline =================

// mux_tx_data buffer write
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (idx = 0; idx < CHANNELS; idx = idx + 1)
            mux_tx_data[idx] <= 8'd0;
    end else begin
        // Optimized: Only update selected channel, others keep their value
        if (sel_chan_stage1 < CHANNELS)
            mux_tx_data[sel_chan_stage1] <= tx_data_stage1;
    end
end

// Pipeline: time_slot_stage2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        time_slot_stage2 <= {CHAN_WIDTH{1'b0}};
    else
        time_slot_stage2 <= time_slot_stage1;
end

// Pipeline: sel_chan_stage2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sel_chan_stage2 <= {CHAN_WIDTH{1'b0}};
    else
        sel_chan_stage2 <= sel_chan_stage1;
end

// Pipeline: cycle_start_stage2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cycle_start_stage2 <= 1'b0;
    else
        cycle_start_stage2 <= cycle_start_stage1;
end

// Pipeline: rxd_bus_stage2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rxd_bus_stage2 <= {CHANNELS{1'b0}};
    else
        rxd_bus_stage2 <= rxd_bus_stage1;
end

// Baud table initialization (not modified in logic, can be parameterized externally)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (idx = 0; idx < CHANNELS; idx = idx + 1)
            baud_table[idx] <= 16'd0;
    end
end

// Pipeline: current_baud_stage2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        current_baud_stage2 <= 16'd0;
    else if (sel_chan_stage1 < CHANNELS)
        current_baud_stage2 <= baud_table[sel_chan_stage1];
    else
        current_baud_stage2 <= 16'd0;
end

// Pipeline: tx_shift_stage2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        tx_shift_stage2 <= 8'd0;
    else if (sel_chan_stage1 < CHANNELS)
        tx_shift_stage2 <= mux_tx_data[sel_chan_stage1];
    else
        tx_shift_stage2 <= 8'd0;
end

//================= Stage 3: Output and Data Pipeline =================

// Pipeline: rx_data_stage3
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rx_data_stage3 <= 8'd0;
    else if (sel_chan_stage2 < CHANNELS)
        rx_data_stage3 <= mux_rx_data[sel_chan_stage2];
    else
        rx_data_stage3 <= 8'd0;
end

// Output: rx_data
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rx_data <= 8'd0;
    else
        rx_data <= rx_data_stage3;
end

// Pipeline: tx_shift_stage3
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        tx_shift_stage3 <= 8'd0;
    else
        tx_shift_stage3 <= tx_shift_stage2;
end

// Pipeline: current_baud_stage3
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        current_baud_stage3 <= 16'd0;
    else
        current_baud_stage3 <= current_baud_stage2;
end

// Pipeline: time_slot_stage3
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        time_slot_stage3 <= {CHAN_WIDTH{1'b0}};
    else
        time_slot_stage3 <= time_slot_stage2;
end

// Pipeline: cycle_start_stage3
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cycle_start_stage3 <= 1'b0;
    else
        cycle_start_stage3 <= cycle_start_stage2;
end

// TXD bus update logic (optimized)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        txd_bus <= {CHANNELS{1'b1}};
    else if (cycle_start_stage2) begin
        // Set all bits to 1, then only set the selected slot if in range
        txd_bus <= {CHANNELS{1'b1}};
        if (time_slot_stage2 < CHANNELS)
            txd_bus[time_slot_stage2] <= tx_shift_stage2[0];
    end
end

//================= Stage 4: RX Data Update =================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (idx = 0; idx < CHANNELS; idx = idx + 1)
            mux_rx_data[idx] <= 8'd0;
    end else begin
        // Optimized: use range checking for RX bus update
        for (idx = 0; idx < CHANNELS; idx = idx + 1) begin
            if (rxd_bus_stage2[idx] == 1'b0)
                mux_rx_data[idx] <= {mux_rx_data[idx][6:0], rxd_bus_stage2[idx]};
        end
    end
end

endmodule