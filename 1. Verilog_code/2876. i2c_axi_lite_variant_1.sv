//SystemVerilog
module i2c_axi_lite #(
    parameter C_S_AXI_ADDR_WIDTH = 4,
    parameter C_S_AXI_DATA_WIDTH = 32
)(
    // AXI-Lite interface
    input  S_AXI_ACLK,
    input  S_AXI_ARESETN,
    input  [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  reg_write_en,
    // I2C physical interface
    inout sda,
    inout scl,
    // Unique feature: Bus register mapping
    output reg [31:0] reg_ctrl,
    output reg [31:0] reg_status,
    input  [31:0] reg_txdata,
    output [31:0] reg_rxdata
);

// Register captured input signals - split into two stages for better timing
reg [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR_r1, S_AXI_AWADDR_r2;
reg [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA_r1, S_AXI_WDATA_r2;
reg reg_write_en_r1, reg_write_en_r2;
reg [31:0] reg_txdata_r1, reg_txdata_r2;

// Pre-decoded address signals to reduce critical path in second stage
reg addr_is_ctrl_r, addr_is_status_r;

// First registration stage
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        S_AXI_AWADDR_r1 <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        S_AXI_WDATA_r1 <= {C_S_AXI_DATA_WIDTH{1'b0}};
        reg_write_en_r1 <= 1'b0;
        reg_txdata_r1 <= 32'h0000_0000;
    end else begin
        S_AXI_AWADDR_r1 <= S_AXI_AWADDR;
        S_AXI_WDATA_r1 <= S_AXI_WDATA;
        reg_write_en_r1 <= reg_write_en;
        reg_txdata_r1 <= reg_txdata;
    end
end

// Pre-decode address in separate stage to break long combinational path
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        addr_is_ctrl_r <= 1'b0;
        addr_is_status_r <= 1'b0;
        S_AXI_AWADDR_r2 <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        S_AXI_WDATA_r2 <= {C_S_AXI_DATA_WIDTH{1'b0}};
        reg_write_en_r2 <= 1'b0;
        reg_txdata_r2 <= 32'h0000_0000;
    end else begin
        // Pre-decode address for next cycle
        addr_is_ctrl_r <= (S_AXI_AWADDR_r1[3:0] == 4'h0);
        addr_is_status_r <= (S_AXI_AWADDR_r1[3:0] == 4'h4);
        
        // Pass through other signals
        S_AXI_AWADDR_r2 <= S_AXI_AWADDR_r1;
        S_AXI_WDATA_r2 <= S_AXI_WDATA_r1;
        reg_write_en_r2 <= reg_write_en_r1;
        reg_txdata_r2 <= reg_txdata_r1;
    end
end

// Register update using pre-decoded address - reduced mux complexity
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        reg_ctrl <= 32'h0000_0000;
        reg_status <= 32'h0000_0000;
    end else begin
        // Use pre-decoded address and direct enable logic instead of case statement
        if (reg_write_en_r2 && addr_is_ctrl_r) begin
            reg_ctrl <= S_AXI_WDATA_r2;
        end
        
        if (reg_write_en_r2 && addr_is_status_r) begin
            reg_status <= S_AXI_WDATA_r2;
        end
    end
end

// Define signals for i2c_core - use second stage registered values
wire i2c_clk, i2c_rst;
wire [7:0] i2c_data_in, i2c_data_out;

// Pre-compute constant expressions
assign i2c_clk = S_AXI_ACLK;
assign i2c_rst = ~S_AXI_ARESETN;
assign i2c_data_in = reg_txdata_r2[7:0];  // Use second-stage registered input

// Zero-extension moved to separate register to reduce fanout
reg [31:0] reg_rxdata_int;
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        reg_rxdata_int <= 32'h0000_0000;
    end else begin
        reg_rxdata_int <= {24'h0, i2c_data_out};
    end
end

assign reg_rxdata = reg_rxdata_int;

// Integration with basic I2C core (stub for integration)
// Comment or replace with actual implementation
/* 
i2c_core u_core (
    .clk(i2c_clk),
    .rst(i2c_rst),
    .sda(sda),
    .scl(scl),
    .data_in(i2c_data_in),
    .data_out(i2c_data_out)
);
*/
endmodule