//SystemVerilog
module secure_regfile #(
    parameter DW = 32,
    parameter AW = 4,
    parameter N_DOMAINS = 4
)(
    input clk,
    input rst_n,
    input [1:0] curr_domain,   // 当前安全域
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output reg access_violation
);
// 安全策略配置 - 预解码以减少选择延迟
localparam DOMAIN0_MASK = 16'hFFFF; // 特权域可访问全部
localparam DOMAIN1_MASK = 16'h00FF;
localparam DOMAIN2_MASK = 16'h000F;
localparam DOMAIN3_MASK = 16'h0003;

reg [DW-1:0] storage [0:(1<<AW)-1];
wire [15:0] addr_mask;
reg [DW-1:0] dout_reg;

// 为curr_domain添加缓冲寄存器，减少扇出负载
reg [1:0] curr_domain_buf1, curr_domain_buf2;
always @(posedge clk) begin
    curr_domain_buf1 <= curr_domain;
    curr_domain_buf2 <= curr_domain;
end

// 地址访问权限解码 - 分离解码器以减少扇出负载
wire [15:0] domain0_mask = DOMAIN0_MASK;
wire [15:0] domain1_mask = DOMAIN1_MASK;
wire [15:0] domain2_mask = DOMAIN2_MASK;
wire [15:0] domain3_mask = DOMAIN3_MASK;

wire domain0_sel = (curr_domain_buf1 == 2'b00);
wire domain1_sel = (curr_domain_buf1 == 2'b01);
wire domain2_sel = (curr_domain_buf1 == 2'b10);
wire domain3_sel = (curr_domain_buf1 == 2'b11);

// 为addr_mask添加缓冲，分散负载
assign addr_mask = (domain0_sel) ? domain0_mask :
                  (domain1_sel) ? domain1_mask :
                  (domain2_sel) ? domain2_mask : 
                  domain3_mask;

reg [15:0] addr_mask_buf1, addr_mask_buf2;
always @(posedge clk) begin
    addr_mask_buf1 <= addr_mask;
    addr_mask_buf2 <= addr_mask;
end

// 简化边界检查，分离读写路径逻辑
wire addr_in_range = 1'b1;
wire mask_valid = |addr_mask_buf1;
wire has_permission = addr < 16 ? addr_mask_buf1[addr] : 1'b0; // 保护边界条件
wire valid_access = addr_in_range && has_permission && mask_valid;

// 为读路径和写路径准备单独的valid信号，平衡负载
reg valid_access_read, valid_access_write;
always @(posedge clk) begin
    valid_access_read <= valid_access;
    valid_access_write <= valid_access;
end

// 为存储器读写操作分配缓冲
reg [AW-1:0] addr_read, addr_write;
always @(posedge clk) begin
    addr_read <= addr;
    addr_write <= addr;
end

// 寄存器读取 - 使用缓冲地址减少存储器扇出
always @(posedge clk) begin
    dout_reg <= valid_access_read ? storage[addr_read] : {DW{1'b0}};
end

// 访问控制逻辑 - 分离读写控制以平衡路径
always @(posedge clk) begin
    if (!rst_n) begin
        access_violation <= 0;
    end else begin
        access_violation <= wr_en && !valid_access_write; // 简化判断，减少逻辑层级
    end
end

// 存储器写入逻辑，使用缓冲地址
reg wr_en_buf;
reg [DW-1:0] din_buf;
always @(posedge clk) begin
    wr_en_buf <= wr_en;
    din_buf <= din;
end

// 将初始化逻辑分离出来，减少复位路径延迟
integer i;
always @(posedge clk) begin
    if (!rst_n) begin
        for (i = 0; i < (1<<AW); i = i + 1) begin
            storage[i] <= {DW{1'b0}};
        end
    end else if (wr_en_buf && valid_access_write) begin
        storage[addr_write] <= din_buf;
    end
end

// 使用寄存器输出以减少读取关键路径
assign dout = dout_reg;

endmodule