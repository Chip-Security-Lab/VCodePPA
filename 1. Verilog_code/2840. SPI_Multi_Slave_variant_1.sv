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

// Input mapping
wire [7:0] tx_data_array [0:SLAVES-1];
assign tx_data_array[0] = tx_data_0;
assign tx_data_array[1] = tx_data_1;
assign tx_data_array[2] = tx_data_2;
assign tx_data_array[3] = tx_data_3;

// --- Forward Retiming Pipeline Registers (moved past combinational logic) --- //
// Pipeline Stage 1: Slave select decode (no register here)
wire [DECODE_WIDTH-1:0] active_slave_comb;
wire [SLAVES-1:0]       cs_n_comb;

assign active_slave_comb = slave_sel;

genvar idx;
generate
    for (idx = 0; idx < SLAVES; idx = idx + 1) begin : CS_DECODE_GEN
        assign cs_n_comb[idx] = (slave_sel == idx) ? 1'b0 : 1'b1;
    end
endgenerate

// Pipeline Stage 2: Registers after combinational decode
reg [DECODE_WIDTH-1:0] active_slave_stage2;
reg [SLAVES-1:0]       cs_n_stage2;
reg [7:0]              mux_data_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        active_slave_stage2 <= {DECODE_WIDTH{1'b0}};
        cs_n_stage2         <= {SLAVES{1'b1}};
        mux_data_stage2     <= 8'b0;
    end else begin
        active_slave_stage2 <= active_slave_comb;
        cs_n_stage2         <= cs_n_comb;
        mux_data_stage2     <= tx_data_array[active_slave_comb];
    end
end

// Pipeline Stage 3: SPI shift, registered on sclk
reg [DECODE_WIDTH-1:0] active_slave_stage3;
reg [SLAVES-1:0]       cs_n_stage3;
reg [7:0]              mux_data_stage3;
reg [7:0]              shift_reg_stage3;

always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        active_slave_stage3 <= {DECODE_WIDTH{1'b0}};
        cs_n_stage3         <= {SLAVES{1'b1}};
        mux_data_stage3     <= 8'b0;
        shift_reg_stage3    <= 8'b0;
    end else begin
        active_slave_stage3 <= active_slave_stage2;
        cs_n_stage3         <= cs_n_stage2;
        mux_data_stage3     <= mux_data_stage2;
        if (!cs_n_stage2[active_slave_stage2]) begin
            shift_reg_stage3 <= mux_data_stage2;
        end
    end
end

// Pipeline Stage 4: SPI shift operation and output latch
reg [7:0] shift_reg_stage4;
reg       miso_stage4;
reg [7:0] rx_data_stage4 [0:SLAVES-1];

always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg_stage4    <= 8'b0;
        miso_stage4         <= 1'b0;
        rx_data_stage4[0]   <= 8'b0;
        rx_data_stage4[1]   <= 8'b0;
        rx_data_stage4[2]   <= 8'b0;
        rx_data_stage4[3]   <= 8'b0;
    end else begin
        shift_reg_stage4    <= {shift_reg_stage3[6:0], mosi};
        miso_stage4         <= shift_reg_stage3[7];
        if (!cs_n_stage3[active_slave_stage3]) begin
            rx_data_stage4[active_slave_stage3] <= {shift_reg_stage3[6:0], mosi};
        end
    end
end

// Output mapping from rx_data_stage4 to rx_data_array
reg [7:0] rx_data_array [0:SLAVES-1];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data_array[0] <= 8'b0;
        rx_data_array[1] <= 8'b0;
        rx_data_array[2] <= 8'b0;
        rx_data_array[3] <= 8'b0;
    end else begin
        rx_data_array[0] <= rx_data_stage4[0];
        rx_data_array[1] <= rx_data_stage4[1];
        rx_data_array[2] <= rx_data_stage4[2];
        rx_data_array[3] <= rx_data_stage4[3];
    end
end

// Output mapping to rx_data_x
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data_0 <= 8'b0;
        rx_data_1 <= 8'b0;
        rx_data_2 <= 8'b0;
        rx_data_3 <= 8'b0;
    end else begin
        rx_data_0 <= rx_data_array[0];
        rx_data_1 <= rx_data_array[1];
        rx_data_2 <= rx_data_array[2];
        rx_data_3 <= rx_data_array[3];
    end
end

// Final cs_n output (registered to clk)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cs_n <= {SLAVES{1'b1}};
    end else begin
        cs_n <= cs_n_stage3;
    end
end

// Output miso
assign miso = miso_stage4;

endmodule