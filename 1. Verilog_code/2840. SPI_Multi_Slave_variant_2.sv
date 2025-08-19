//SystemVerilog
module SPI_Multi_Slave #(
    parameter SLAVES = 4,
    parameter DECODE_WIDTH = 2
)(
    input wire clk,
    input wire rst_n,
    input wire [DECODE_WIDTH-1:0] slave_sel,
    output reg [SLAVES-1:0] cs_n,
    input wire sclk,
    input wire mosi,
    output wire miso,
    input wire [7:0] tx_data_0,
    input wire [7:0] tx_data_1,
    input wire [7:0] tx_data_2,
    input wire [7:0] tx_data_3,
    output reg [7:0] rx_data_0,
    output reg [7:0] rx_data_1,
    output reg [7:0] rx_data_2,
    output reg [7:0] rx_data_3
);

// Input data array
wire [7:0] tx_data_array [0:SLAVES-1];
reg [7:0] rx_data_array [0:SLAVES-1];

// Pipeline registers for chip select and slave selection
reg [DECODE_WIDTH-1:0] active_slave_reg_stage1;
reg [DECODE_WIDTH-1:0] active_slave_reg_stage2;

// Pipeline registers for SCLK domain
reg [DECODE_WIDTH-1:0] active_slave_sclk_stage1;
reg [DECODE_WIDTH-1:0] active_slave_sclk_stage2;
reg [7:0] tx_shift_reg_sclk_stage1;
reg [7:0] tx_shift_reg_sclk_stage2;

// Data shift pipeline
reg [7:0] tx_shift_reg_stage1;
reg [7:0] tx_shift_reg_stage2;

// MISO output register for pipeline
reg miso_stage1;
reg miso_stage2;

// Assign input data to array for easier access
assign tx_data_array[0] = tx_data_0;
assign tx_data_array[1] = tx_data_1;
assign tx_data_array[2] = tx_data_2;
assign tx_data_array[3] = tx_data_3;

// Optimized chip select decoder
always @(*) begin
    cs_n = {SLAVES{1'b1}};
    if (slave_sel < SLAVES)
        cs_n[slave_sel] = 1'b0;
end

// Pipeline stage 1: Active slave register update (CLK domain)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        active_slave_reg_stage1 <= {DECODE_WIDTH{1'b0}};
    end else if (cs_n == {SLAVES{1'b1}}) begin
        active_slave_reg_stage1 <= slave_sel;
    end
end

// Pipeline stage 2: Register slave selection for use in SCLK domain (CLK domain)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        active_slave_reg_stage2 <= {DECODE_WIDTH{1'b0}};
    end else begin
        active_slave_reg_stage2 <= active_slave_reg_stage1;
    end
end

// SCLK domain pipeline: stage 1 - prepare data and slave selection
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        tx_shift_reg_sclk_stage1 <= 8'b0;
        active_slave_sclk_stage1 <= {DECODE_WIDTH{1'b0}};
    end else if (active_slave_reg_stage2 < SLAVES && cs_n[active_slave_reg_stage2] == 1'b0) begin
        tx_shift_reg_sclk_stage1 <= tx_data_array[active_slave_reg_stage2];
        active_slave_sclk_stage1 <= active_slave_reg_stage2;
    end
end

// SCLK domain pipeline: stage 2 - hold previous stage data
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        tx_shift_reg_sclk_stage2 <= 8'b0;
        active_slave_sclk_stage2 <= {DECODE_WIDTH{1'b0}};
    end else begin
        tx_shift_reg_sclk_stage2 <= tx_shift_reg_sclk_stage1;
        active_slave_sclk_stage2 <= active_slave_sclk_stage1;
    end
end

// SCLK domain pipeline: stage 1 for data shift register
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        tx_shift_reg_stage1 <= 8'b0;
    end else begin
        tx_shift_reg_stage1 <= tx_shift_reg_sclk_stage2;
    end
end

// SCLK domain pipeline: stage 2 for data shift register
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        tx_shift_reg_stage2 <= 8'b0;
    end else begin
        tx_shift_reg_stage2 <= tx_shift_reg_stage1;
    end
end

// SCLK domain pipeline: stage 1 for miso output
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        miso_stage1 <= 1'b0;
    end else begin
        miso_stage1 <= tx_shift_reg_stage2[7];
    end
end

// SCLK domain pipeline: stage 2 for miso output
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        miso_stage2 <= 1'b0;
    end else begin
        miso_stage2 <= miso_stage1;
    end
end

// SCLK domain: receive data for selected slave (now pipeline stage aligned)
always @(posedge sclk or negedge rst_n) begin
    integer idx;
    if (!rst_n) begin
        for (idx = 0; idx < SLAVES; idx = idx + 1)
            rx_data_array[idx] <= 8'b0;
    end else if (active_slave_sclk_stage2 < SLAVES && cs_n[active_slave_sclk_stage2] == 1'b0) begin
        rx_data_array[active_slave_sclk_stage2] <= {tx_shift_reg_sclk_stage2[6:0], miso};
    end
end

// CLK domain: synchronize output registers
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

assign miso = miso_stage2;

endmodule