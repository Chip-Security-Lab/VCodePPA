//SystemVerilog
//============================================================
// 顶层模块 - 具有AXI4-Lite接口的跨时钟域数据同步器
//============================================================
module cross_domain_sync #(
    parameter BUS_WIDTH = 16,
    parameter ADDR_WIDTH = 8
) (
    // 全局时钟和复位
    input  wire                     s_axi_aclk,
    input  wire                     s_axi_aresetn,
    
    // AXI4-Lite写地址通道
    input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire                     s_axi_awvalid,
    output wire                     s_axi_awready,
    
    // AXI4-Lite写数据通道
    input  wire [31:0]              s_axi_wdata,
    input  wire [3:0]               s_axi_wstrb,
    input  wire                     s_axi_wvalid,
    output wire                     s_axi_wready,
    
    // AXI4-Lite写响应通道
    output wire [1:0]               s_axi_bresp,
    output wire                     s_axi_bvalid,
    input  wire                     s_axi_bready,
    
    // AXI4-Lite读地址通道
    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire                     s_axi_arvalid,
    output wire                     s_axi_arready,
    
    // AXI4-Lite读数据通道
    output wire [31:0]              s_axi_rdata,
    output wire [1:0]               s_axi_rresp,
    output wire                     s_axi_rvalid,
    input  wire                     s_axi_rready,
    
    // 目标时钟域信号
    input  wire                     dst_clk,
    input  wire                     dst_rst,
    output wire [BUS_WIDTH-1:0]     dst_data,
    output wire                     dst_valid,
    input  wire                     dst_ready
);

    // 内部寄存器和信号定义
    reg [BUS_WIDTH-1:0]  src_data_reg;
    reg                  src_valid_reg;
    wire                 src_ready;
    
    // 连接源域和目标域的同步信号
    wire src_toggle_flag;
    wire [2:0] dst_sync_flag;
    
    // 数据通路连接
    wire [BUS_WIDTH-1:0] transfer_data;
    
    // AXI4-Lite寄存器接口状态机
    localparam IDLE = 2'b00;
    localparam WRITE = 2'b01;
    localparam READ = 2'b10;
    localparam RESP = 2'b11;
    
    // AXI4-Lite接口寄存器和状态
    reg [1:0]  axi_state;
    reg [ADDR_WIDTH-1:0] axi_awaddr_reg;
    reg [ADDR_WIDTH-1:0] axi_araddr_reg;
    reg [31:0] axi_rdata_reg;
    
    // AXI4-Lite接口输出信号
    reg        axi_awready_reg;
    reg        axi_wready_reg;
    reg        axi_bvalid_reg;
    reg [1:0]  axi_bresp_reg;
    reg        axi_arready_reg;
    reg        axi_rvalid_reg;
    reg [1:0]  axi_rresp_reg;
    
    // AXI4-Lite输出信号赋值
    assign s_axi_awready = axi_awready_reg;
    assign s_axi_wready = axi_wready_reg;
    assign s_axi_bresp = axi_bresp_reg;
    assign s_axi_bvalid = axi_bvalid_reg;
    assign s_axi_arready = axi_arready_reg;
    assign s_axi_rdata = axi_rdata_reg;
    assign s_axi_rresp = axi_rresp_reg;
    assign s_axi_rvalid = axi_rvalid_reg;
    
    // 寄存器地址映射
    localparam SRC_DATA_REG_ADDR = 'h00;
    localparam SRC_CTRL_REG_ADDR = 'h04;
    localparam STATUS_REG_ADDR = 'h08;
    
    // AXI4-Lite状态机实现
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_state <= IDLE;
            axi_awready_reg <= 1'b0;
            axi_wready_reg <= 1'b0;
            axi_bvalid_reg <= 1'b0;
            axi_bresp_reg <= 2'b00;
            axi_arready_reg <= 1'b0;
            axi_rvalid_reg <= 1'b0;
            axi_rresp_reg <= 2'b00;
            axi_rdata_reg <= 32'h0;
            src_data_reg <= {BUS_WIDTH{1'b0}};
            src_valid_reg <= 1'b0;
        end else begin
            // 默认将src_valid_reg复位，仅在写入控制寄存器时置位
            src_valid_reg <= 1'b0;
            
            case (axi_state)
                IDLE: begin
                    if (s_axi_awvalid && s_axi_wvalid) begin
                        // 写操作
                        axi_awready_reg <= 1'b1;
                        axi_wready_reg <= 1'b1;
                        axi_awaddr_reg <= s_axi_awaddr;
                        axi_state <= WRITE;
                    end else if (s_axi_arvalid) begin
                        // 读操作
                        axi_arready_reg <= 1'b1;
                        axi_araddr_reg <= s_axi_araddr;
                        axi_state <= READ;
                    end
                end
                
                WRITE: begin
                    // 处理写请求
                    axi_awready_reg <= 1'b0;
                    axi_wready_reg <= 1'b0;
                    
                    // 寄存器写入逻辑
                    if (axi_awaddr_reg[7:0] == SRC_DATA_REG_ADDR) begin
                        src_data_reg <= s_axi_wdata[BUS_WIDTH-1:0];
                    end else if (axi_awaddr_reg[7:0] == SRC_CTRL_REG_ADDR) begin
                        // 当写入控制寄存器且最低位为1时触发数据传输
                        if (s_axi_wdata[0]) begin
                            src_valid_reg <= 1'b1;
                        end
                    end
                    
                    // 发送写响应
                    axi_bvalid_reg <= 1'b1;
                    axi_bresp_reg <= 2'b00; // OKAY响应
                    axi_state <= RESP;
                end
                
                READ: begin
                    // 处理读请求
                    axi_arready_reg <= 1'b0;
                    
                    // 寄存器读取逻辑
                    case (axi_araddr_reg[7:0])
                        SRC_DATA_REG_ADDR: begin
                            axi_rdata_reg <= {{(32-BUS_WIDTH){1'b0}}, src_data_reg};
                        end
                        SRC_CTRL_REG_ADDR: begin
                            axi_rdata_reg <= {31'h0, src_valid_reg};
                        end
                        STATUS_REG_ADDR: begin
                            axi_rdata_reg <= {30'h0, dst_valid, src_ready};
                        end
                        default: begin
                            axi_rdata_reg <= 32'h0;
                        end
                    endcase
                    
                    axi_rvalid_reg <= 1'b1;
                    axi_rresp_reg <= 2'b00; // OKAY响应
                    axi_state <= RESP;
                end
                
                RESP: begin
                    // 处理响应，等待主设备确认
                    if (axi_bvalid_reg && s_axi_bready) begin
                        // 写响应被接收
                        axi_bvalid_reg <= 1'b0;
                        axi_state <= IDLE;
                    end else if (axi_rvalid_reg && s_axi_rready) begin
                        // 读响应被接收
                        axi_rvalid_reg <= 1'b0;
                        axi_state <= IDLE;
                    end
                end
                
                default: axi_state <= IDLE;
            endcase
        end
    end
    
    // 源域控制器实例化
    source_controller #(
        .BUS_WIDTH(BUS_WIDTH)
    ) src_ctrl_inst (
        .clk(s_axi_aclk),
        .rst(~s_axi_aresetn),
        .valid_in(src_valid_reg),
        .data_in(src_data_reg),
        .ready_out(src_ready),
        .toggle_flag_out(src_toggle_flag),
        .dst_synced_flag(dst_sync_flag[2]),
        .transfer_data_out(transfer_data)
    );
    
    // 同步器实例化 - 将源域信号同步到目标域
    toggle_synchronizer dst_sync_inst (
        .dst_clk(dst_clk),
        .dst_rst(dst_rst),
        .src_toggle(src_toggle_flag),
        .dst_sync_out(dst_sync_flag)
    );
    
    // 目标域控制器实例化
    destination_controller #(
        .BUS_WIDTH(BUS_WIDTH)
    ) dst_ctrl_inst (
        .clk(dst_clk),
        .rst(dst_rst),
        .sync_flags(dst_sync_flag),
        .transfer_data(transfer_data),
        .dst_ready(dst_ready),
        .dst_data(dst_data),
        .dst_valid(dst_valid)
    );

endmodule

//============================================================
// 源域控制器 - 处理源时钟域的数据传输请求
//============================================================
module source_controller #(
    parameter BUS_WIDTH = 16
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  valid_in,
    input  wire [BUS_WIDTH-1:0]  data_in,
    output reg                   ready_out,
    output reg                   toggle_flag_out,
    input  wire                  dst_synced_flag,
    output reg  [BUS_WIDTH-1:0]  transfer_data_out
);
    
    // 源域控制逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            toggle_flag_out <= 1'b0;
            ready_out <= 1'b1;
            transfer_data_out <= {BUS_WIDTH{1'b0}};
        end else if (valid_in && ready_out) begin
            toggle_flag_out <= ~toggle_flag_out;
            ready_out <= 1'b0;
            transfer_data_out <= data_in;  // 锁存要传输的数据
        end else if (dst_synced_flag == toggle_flag_out) begin
            ready_out <= 1'b1;
        end
    end
    
endmodule

//============================================================
// 切换标志同步器 - 使用多级触发器实现跨时钟域同步
//============================================================
module toggle_synchronizer (
    input  wire  dst_clk,
    input  wire  dst_rst,
    input  wire  src_toggle,
    output reg  [2:0] dst_sync_out
);

    // 2级触发器同步
    always @(posedge dst_clk or posedge dst_rst) begin
        if (dst_rst) begin
            dst_sync_out <= 3'b000;
        end else begin
            dst_sync_out <= {dst_sync_out[1:0], src_toggle};
        end
    end
    
endmodule

//============================================================
// 目标域控制器 - 处理目标时钟域的数据接收
//============================================================
module destination_controller #(
    parameter BUS_WIDTH = 16
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire [2:0]            sync_flags,
    input  wire [BUS_WIDTH-1:0]  transfer_data,
    input  wire                  dst_ready,
    output reg  [BUS_WIDTH-1:0]  dst_data,
    output reg                   dst_valid
);
    
    // 目标域控制逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dst_valid <= 1'b0;
            dst_data <= {BUS_WIDTH{1'b0}};
        end else begin
            // 检测到同步标志的边沿变化，表示有新数据到达
            if (sync_flags[2] != sync_flags[1] && !dst_valid) begin
                dst_data <= transfer_data;
                dst_valid <= 1'b1;
            end else if (dst_valid && dst_ready) begin
                dst_valid <= 1'b0;
            end
        end
    end
    
endmodule