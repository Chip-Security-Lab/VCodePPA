//SystemVerilog
//IEEE 1364-2005 Verilog
module i2c_axi_lite #(
    parameter C_S_AXI_ADDR_WIDTH = 4,
    parameter C_S_AXI_DATA_WIDTH = 32
)(
    // AXI-Lite interface
    input  wire S_AXI_ACLK,
    input  wire S_AXI_ARESETN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire reg_write_en,
    // I2C physical interface
    inout  wire sda,
    inout  wire scl,
    // Unique feature: Bus register mapping
    output reg  [31:0] reg_ctrl,
    output reg  [31:0] reg_status,
    input  wire [31:0] reg_txdata,
    output wire [31:0] reg_rxdata
);

// Pipeline stage signals
// Stage 1: Address Decode
reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_stage1;
reg [C_S_AXI_DATA_WIDTH-1:0] wdata_stage1;
reg reg_write_en_stage1;
reg valid_stage1;

// Stage 2: Register Selection
reg reg_ctrl_sel_stage2;
reg reg_status_sel_stage2;
reg [C_S_AXI_DATA_WIDTH-1:0] wdata_stage2;
reg valid_stage2;

// Stage 3: Register Update
reg reg_update_stage3;
reg [C_S_AXI_DATA_WIDTH-1:0] wdata_stage3;
reg reg_ctrl_sel_stage3;
reg reg_status_sel_stage3;
reg valid_stage3;

// ==================== PIPELINE STAGE 1: Address Decode ====================
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        awaddr_stage1 <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        wdata_stage1 <= {C_S_AXI_DATA_WIDTH{1'b0}};
        reg_write_en_stage1 <= 1'b0;
        valid_stage1 <= 1'b0;
    end else begin
        awaddr_stage1 <= S_AXI_AWADDR;
        wdata_stage1 <= S_AXI_WDATA;
        reg_write_en_stage1 <= reg_write_en;
        valid_stage1 <= 1'b1;
    end
end

// ==================== PIPELINE STAGE 2: Register Selection ====================
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        reg_ctrl_sel_stage2 <= 1'b0;
        reg_status_sel_stage2 <= 1'b0;
        wdata_stage2 <= {C_S_AXI_DATA_WIDTH{1'b0}};
        valid_stage2 <= 1'b0;
    end else if (valid_stage1) begin
        reg_ctrl_sel_stage2 <= ~awaddr_stage1[3] & ~awaddr_stage1[2] & reg_write_en_stage1; // 00xx
        reg_status_sel_stage2 <= ~awaddr_stage1[3] & awaddr_stage1[2] & reg_write_en_stage1; // 01xx
        wdata_stage2 <= wdata_stage1;
        valid_stage2 <= valid_stage1;
    end else begin
        valid_stage2 <= 1'b0;
    end
end

// ==================== PIPELINE STAGE 3: Register Update Preparation ====================
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        reg_update_stage3 <= 1'b0;
        wdata_stage3 <= {C_S_AXI_DATA_WIDTH{1'b0}};
        reg_ctrl_sel_stage3 <= 1'b0;
        reg_status_sel_stage3 <= 1'b0;
        valid_stage3 <= 1'b0;
    end else if (valid_stage2) begin
        reg_update_stage3 <= reg_ctrl_sel_stage2 | reg_status_sel_stage2;
        wdata_stage3 <= wdata_stage2;
        reg_ctrl_sel_stage3 <= reg_ctrl_sel_stage2;
        reg_status_sel_stage3 <= reg_status_sel_stage2;
        valid_stage3 <= valid_stage2;
    end else begin
        valid_stage3 <= 1'b0;
    end
end

// ==================== FINAL STAGE: Register Update ====================
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        reg_ctrl <= 32'h0;
        reg_status <= 32'h0;
    end else if (valid_stage3 && reg_update_stage3) begin
        if (reg_ctrl_sel_stage3) begin
            reg_ctrl <= wdata_stage3;
        end
        if (reg_status_sel_stage3) begin
            reg_status <= wdata_stage3;
        end
    end
end

// ==================== I2C Interface Pipeline ====================
// Stage 1: Capture tx data
reg [7:0] tx_data_stage1;
reg valid_tx_stage1;

// Stage 2: Processing
reg [7:0] tx_data_stage2;
reg valid_tx_stage2;
reg [7:0] rx_data_stage2;

// I2C clock domain signals
wire i2c_clk;
wire i2c_rst_n;
reg [7:0] i2c_rx_data;

// TX data pipeline
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        tx_data_stage1 <= 8'h0;
        valid_tx_stage1 <= 1'b0;
    end else begin
        tx_data_stage1 <= reg_txdata[7:0];
        valid_tx_stage1 <= 1'b1;
    end
end

always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        tx_data_stage2 <= 8'h0;
        valid_tx_stage2 <= 1'b0;
    end else if (valid_tx_stage1) begin
        tx_data_stage2 <= tx_data_stage1;
        valid_tx_stage2 <= valid_tx_stage1;
    end else begin
        valid_tx_stage2 <= 1'b0;
    end
end

// RX data pipeline
reg [31:0] rx_data_out;
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        rx_data_out <= 32'h0;
    end else begin
        rx_data_out <= {24'b0, i2c_rx_data};
    end
end

// Output connections
assign i2c_clk = S_AXI_ACLK;
assign i2c_rst_n = S_AXI_ARESETN;
assign reg_rxdata = rx_data_out;

// I2C core instantiation would connect to the pipelined data
// The I2C core would receive tx_data_stage2 when valid_tx_stage2 is high
/*
i2c_core u_core (
    .clk(i2c_clk),
    .rst_n(i2c_rst_n),
    .sda(sda),
    .scl(scl),
    .tx_data(tx_data_stage2),
    .tx_valid(valid_tx_stage2),
    .rx_data(i2c_rx_data)
);
*/

endmodule