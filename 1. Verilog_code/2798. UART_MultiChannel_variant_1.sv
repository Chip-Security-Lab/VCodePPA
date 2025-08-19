//SystemVerilog
module UART_MultiChannel #(
    parameter CHANNELS = 4,
    parameter CHAN_WIDTH = 2
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [CHAN_WIDTH-1:0] sel_chan,
    output wire [CHANNELS-1:0]   txd_bus,
    input  wire [CHANNELS-1:0]   rxd_bus,
    input  wire [7:0]            tx_data,
    output wire [7:0]            rx_data,
    input  wire                  cycle_start
);

    // Internal register declarations
    reg [CHAN_WIDTH-1:0]    time_slot_reg;
    reg [CHANNELS-1:0]      chan_enable_reg;
    reg [15:0]              baud_table_reg [0:CHANNELS-1];
    reg [7:0]               mux_tx_data_reg [0:CHANNELS-1];
    reg [7:0]               mux_rx_data_reg [0:CHANNELS-1];

    reg [7:0]               tx_shift_reg;
    reg [15:0]              current_baud_reg;

    integer i;

    //==========================================================================
    // Combinational Logic Module for Multiplexing and Configuration
    //==========================================================================
    wire [15:0] current_baud_comb;
    wire [7:0]  tx_shift_comb;
    wire [7:0]  rx_data_comb;

    UART_MultiChannel_comb #(
        .CHANNELS(CHANNELS),
        .CHAN_WIDTH(CHAN_WIDTH)
    ) u_comb (
        .sel_chan(sel_chan),
        .baud_table(baud_table_reg),
        .mux_tx_data(mux_tx_data_reg),
        .mux_rx_data(mux_rx_data_reg),
        .current_baud(current_baud_comb),
        .tx_shift(tx_shift_comb),
        .rx_data(rx_data_comb)
    );

    //==========================================================================
    // TXD Bus Combinational Output
    //==========================================================================
    wire [CHANNELS-1:0] txd_bus_comb;

    UART_MultiChannel_txd_bus #(
        .CHANNELS(CHANNELS),
        .CHAN_WIDTH(CHAN_WIDTH)
    ) u_txd_bus (
        .time_slot(time_slot_reg),
        .cycle_start(cycle_start),
        .tx_shift(tx_shift_reg),
        .rst_n(rst_n),
        .txd_bus(txd_bus_comb)
    );

    assign txd_bus = txd_bus_comb;
    assign rx_data = rx_data_comb;

    //==========================================================================
    // Sequential Logic: Registers and State
    //==========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            time_slot_reg <= {CHAN_WIDTH{1'b0}};
            chan_enable_reg <= {CHANNELS{1'b0}};
            tx_shift_reg <= 8'd0;
            current_baud_reg <= 16'd0;
            for (i = 0; i < CHANNELS; i = i + 1) begin
                mux_tx_data_reg[i] <= 8'd0;
                mux_rx_data_reg[i] <= 8'd0;
                baud_table_reg[i] <= 16'd0;
            end
        end else begin
            // 发送数据缓存写入逻辑
            mux_tx_data_reg[sel_chan] <= tx_data;

            // 时分复用时隙切换
            if (cycle_start) begin
                if (time_slot_reg == CHANNELS-1)
                    time_slot_reg <= {CHAN_WIDTH{1'b0}};
                else
                    time_slot_reg <= time_slot_reg + 1'b1;
            end

            // RXD数据采样和移位
            for (i = 0; i < CHANNELS; i = i + 1) begin
                if (rxd_bus[i] == 1'b0) begin
                    mux_rx_data_reg[i] <= {mux_rx_data_reg[i][6:0], rxd_bus[i]};
                end
            end

            // 配置加载
            current_baud_reg <= current_baud_comb;
            tx_shift_reg <= tx_shift_comb;
        end
    end

endmodule

//==============================================================================
// Combinational Logic Submodule for Multiplexing and Configuration
//==============================================================================
module UART_MultiChannel_comb #(
    parameter CHANNELS = 4,
    parameter CHAN_WIDTH = 2
)(
    input  wire [CHAN_WIDTH-1:0] sel_chan,
    input  wire [15:0]           baud_table [0:CHANNELS-1],
    input  wire [7:0]            mux_tx_data [0:CHANNELS-1],
    input  wire [7:0]            mux_rx_data [0:CHANNELS-1],
    output wire [15:0]           current_baud,
    output wire [7:0]            tx_shift,
    output wire [7:0]            rx_data
);
    assign current_baud = baud_table[sel_chan];
    assign tx_shift     = mux_tx_data[sel_chan];
    assign rx_data      = mux_rx_data[sel_chan];
endmodule

//==============================================================================
// Combinational Logic Submodule for TXD Bus Output
//==============================================================================
module UART_MultiChannel_txd_bus #(
    parameter CHANNELS = 4,
    parameter CHAN_WIDTH = 2
)(
    input  wire [CHAN_WIDTH-1:0] time_slot,
    input  wire                  cycle_start,
    input  wire [7:0]            tx_shift,
    input  wire                  rst_n,
    output wire [CHANNELS-1:0]   txd_bus
);
    reg [CHANNELS-1:0] txd_bus_comb;

    integer j;
    always @(*) begin
        txd_bus_comb = {CHANNELS{1'b1}};
        if (rst_n && cycle_start) begin
            for (j = 0; j < CHANNELS; j = j + 1) begin
                if (j == time_slot)
                    txd_bus_comb[j] = tx_shift[0];
            end
        end
    end

    assign txd_bus = txd_bus_comb;
endmodule