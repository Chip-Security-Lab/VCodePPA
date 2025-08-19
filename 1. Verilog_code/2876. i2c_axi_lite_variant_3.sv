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

// 优化地址解码路径 - 使用地址位直接解码而不是比较完整地址
// 减少比较器延迟，平衡逻辑路径
wire addr_ctrl_sel = ~S_AXI_AWADDR[3] & ~S_AXI_AWADDR[2] & ~S_AXI_AWADDR[1] & ~S_AXI_AWADDR[0];
wire addr_status_sel = ~S_AXI_AWADDR[3] & ~S_AXI_AWADDR[2] & S_AXI_AWADDR[1] & ~S_AXI_AWADDR[0];

// 预计算写使能信号，减少关键路径延迟
wire write_ctrl_en = reg_write_en & addr_ctrl_sel;
wire write_status_en = reg_write_en & addr_status_sel;

// Control register management - 优化后的时序逻辑
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        reg_ctrl <= 32'h0000_0000;
    end else if (write_ctrl_en) begin
        reg_ctrl <= S_AXI_WDATA;
    end
end

// Status register management - 优化后的时序逻辑
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
    if (!S_AXI_ARESETN) begin
        reg_status <= 32'h0000_0000;
    end else if (write_status_en) begin
        reg_status <= S_AXI_WDATA;
    end
end

// 简化I2C数据路径并预计算常量部分
wire i2c_rst_n = S_AXI_ARESETN; // 避免使用反相器减少延迟
wire [7:0] i2c_data_in = reg_txdata[7:0]; // 直接截取低8位
wire [7:0] i2c_data_out;

// 使用寄存器零扩展，优化数据路径
assign reg_rxdata = {24'h0, i2c_data_out};

// Integration with basic I2C core (stub for integration)
// Comment or replace with actual implementation
/* 
i2c_core u_core (
    .clk(S_AXI_ACLK),       // 直接使用系统时钟，减少路径
    .rst_n(i2c_rst_n),      // 使用低有效复位信号减少反相器
    .sda(sda),
    .scl(scl),
    .data_in(i2c_data_in),
    .data_out(i2c_data_out)
);
*/
endmodule