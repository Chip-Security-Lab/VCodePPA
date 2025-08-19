//SystemVerilog
module SPI_Multi_Slave #(
    parameter SLAVES = 4,
    parameter DECODE_WIDTH = 2
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [DECODE_WIDTH-1:0] slave_sel,
    output reg  [SLAVES-1:0]     cs_n,
    input  wire                  sclk,
    input  wire                  mosi,
    output wire                  miso,
    input  wire [7:0]            tx_data_0,
    input  wire [7:0]            tx_data_1,
    input  wire [7:0]            tx_data_2,
    input  wire [7:0]            tx_data_3,
    output reg  [7:0]            rx_data_0,
    output reg  [7:0]            rx_data_1,
    output reg  [7:0]            rx_data_2,
    output reg  [7:0]            rx_data_3
);

// Internal signals
reg  [DECODE_WIDTH-1:0] active_slave_q, active_slave_qq;
reg  [7:0] tx_mux_q, tx_mux_qq;
reg  [7:0] slave_tx_data_q;
wire [7:0] tx_data_array [0:SLAVES-1];
reg  [7:0] rx_data_array [0:SLAVES-1];
reg  [7:0] rx_data_next_array [0:SLAVES-1];
reg  [SLAVES-1:0] cs_n_q, cs_n_qq;

// Array mapping
assign tx_data_array[0] = tx_data_0;
assign tx_data_array[1] = tx_data_1;
assign tx_data_array[2] = tx_data_2;
assign tx_data_array[3] = tx_data_3;

// Pipeline register for active_slave
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        active_slave_q  <= {DECODE_WIDTH{1'b0}};
        active_slave_qq <= {DECODE_WIDTH{1'b0}};
    end else begin
        // Only update on deselection
        if (cs_n == {SLAVES{1'b1}})
            active_slave_q <= slave_sel;
        active_slave_qq <= active_slave_q;
    end
end

// Optimized chip select logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cs_n_q  <= {SLAVES{1'b1}};
        cs_n_qq <= {SLAVES{1'b1}};
    end else begin
        cs_n_q  <= {SLAVES{1'b1}};
        if (active_slave_q < SLAVES)
            cs_n_q[active_slave_q] <= 1'b0;
        cs_n_qq <= cs_n_q;
    end
end

always @* begin
    cs_n = cs_n_qq;
end

// Optimized TX data multiplexer
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        slave_tx_data_q <= 8'd0;
    end else begin
        if (active_slave_qq < SLAVES)
            slave_tx_data_q <= tx_data_array[active_slave_qq];
        else
            slave_tx_data_q <= 8'd0;
    end
end

// Pipeline TX register
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        tx_mux_q  <= 8'd0;
        tx_mux_qq <= 8'd0;
    end else begin
        if ((active_slave_qq < SLAVES) && (!cs_n_qq[active_slave_qq])) begin
            tx_mux_q  <= slave_tx_data_q;
            tx_mux_qq <= tx_mux_q;
        end
    end
end

// Optimized RX data assignment
integer idx;
always @* begin
    for (idx = 0; idx < SLAVES; idx = idx + 1) begin
        rx_data_next_array[idx] = rx_data_array[idx];
    end
    if ((active_slave_qq < SLAVES) && (!cs_n_qq[active_slave_qq])) begin
        rx_data_next_array[active_slave_qq] = {tx_mux_q[6:0], miso};
    end
end

always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        for (idx = 0; idx < SLAVES; idx = idx + 1)
            rx_data_array[idx] <= 8'd0;
    end else begin
        for (idx = 0; idx < SLAVES; idx = idx + 1)
            rx_data_array[idx] <= rx_data_next_array[idx];
    end
end

// Output mapping for RX data
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data_0 <= 8'd0;
        rx_data_1 <= 8'd0;
        rx_data_2 <= 8'd0;
        rx_data_3 <= 8'd0;
    end else begin
        rx_data_0 <= rx_data_array[0];
        rx_data_1 <= rx_data_array[1];
        rx_data_2 <= rx_data_array[2];
        rx_data_3 <= rx_data_array[3];
    end
end

assign miso = tx_mux_qq[7];

endmodule