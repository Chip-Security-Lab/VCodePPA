//SystemVerilog
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

// 优化地址解码逻辑 - 使用单比特比较
wire addr_is_ctrl   = (S_AXI_AWADDR[3:0] == 4'h0);
wire addr_is_status = (S_AXI_AWADDR[3:0] == 4'h4);

// 寄存器更新逻辑 - 优化比较链
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        reg_ctrl   <= 32'h0000_0000;
        reg_status <= 32'h0000_0000;
    end else if (reg_write_en) begin
        // 使用预解码的地址信号来简化比较逻辑
        if (addr_is_ctrl)
            reg_ctrl <= S_AXI_WDATA;
        else if (addr_is_status)
            reg_status <= S_AXI_WDATA;
    end
end

// 定义 I2C 核心信号
wire i2c_clk, i2c_rst;
wire [7:0] i2c_data_in, i2c_data_out;

// 信号分配
assign i2c_clk = S_AXI_ACLK;
assign i2c_rst = ~S_AXI_ARESETN;
assign i2c_data_in = reg_txdata[7:0];
assign reg_rxdata = {24'b0, i2c_data_out}; // 使用前导零填充

// I2C 核心集成点（存根，供集成使用）
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