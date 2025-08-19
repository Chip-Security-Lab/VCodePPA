//SystemVerilog
module hierarchical_reset_dist (
    // 时钟和复位信号
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    
    // AXI4-Lite写地址通道
    input wire [31:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // AXI4-Lite写数据通道
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid, 
    output reg s_axi_wready,
    
    // AXI4-Lite写响应通道
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // AXI4-Lite读地址通道
    input wire [31:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // AXI4-Lite读数据通道
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // 原始接口输出
    output wire [7:0] subsystem_rst
);

    // 内部寄存器
    reg global_rst;
    reg [1:0] domain_select;
    
    // AXI4-Lite通信状态
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;
    localparam RESP = 2'b11;
    
    reg [1:0] write_state;
    reg [1:0] read_state;
    reg [31:0] read_addr;
    
    // 地址映射定义
    localparam ADDR_GLOBAL_RST = 4'h0;      // 0x00: 全局复位
    localparam ADDR_DOMAIN_SELECT = 4'h4;   // 0x04: 域选择
    localparam ADDR_SUBSYSTEM_RST = 4'h8;   // 0x08: 子系统复位状态(只读)
    
    // 写通道状态机 - 状态转换逻辑
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            write_state <= IDLE;
        end else begin
            case (write_state)
                IDLE: begin
                    if (s_axi_awvalid && s_axi_wvalid) begin
                        write_state <= RESP;
                    end else if (s_axi_awvalid) begin
                        write_state <= ADDR;
                    end else if (s_axi_wvalid) begin
                        write_state <= DATA;
                    end
                end
                
                ADDR: begin
                    if (s_axi_wvalid) begin
                        write_state <= RESP;
                    end
                end
                
                DATA: begin
                    if (s_axi_awvalid) begin
                        write_state <= RESP;
                    end
                end
                
                RESP: begin
                    if (s_axi_bready) begin
                        write_state <= IDLE;
                    end
                end
            endcase
        end
    end
    
    // 写通道 - 控制信号逻辑
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
        end else begin
            case (write_state)
                IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready <= 1'b1;
                    
                    if (s_axi_awvalid && s_axi_wvalid) begin
                        s_axi_awready <= 1'b0;
                        s_axi_wready <= 1'b0;
                        s_axi_bvalid <= 1'b1;
                    end else if (s_axi_awvalid) begin
                        s_axi_awready <= 1'b0;
                    end else if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b0;
                    end
                end
                
                ADDR: begin
                    s_axi_wready <= 1'b1;
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b0;
                        s_axi_bvalid <= 1'b1;
                    end
                end
                
                DATA: begin
                    s_axi_awready <= 1'b1;
                    if (s_axi_awvalid) begin
                        s_axi_awready <= 1'b0;
                        s_axi_bvalid <= 1'b1;
                    end
                end
                
                RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        s_axi_awready <= 1'b1;
                        s_axi_wready <= 1'b1;
                    end
                end
            endcase
        end
    end
    
    // 写通道 - 数据处理逻辑
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_bresp <= 2'b00;
            global_rst <= 1'b0;
            domain_select <= 2'b00;
        end else begin
            if ((write_state == IDLE && s_axi_awvalid && s_axi_wvalid) || 
                (write_state == ADDR && s_axi_wvalid) || 
                (write_state == DATA && s_axi_awvalid)) begin
                
                // 解码地址并写入对应寄存器
                case (s_axi_awaddr[3:0])
                    ADDR_GLOBAL_RST: begin
                        global_rst <= s_axi_wdata[0];
                        s_axi_bresp <= 2'b00; // OKAY
                    end
                    ADDR_DOMAIN_SELECT: begin
                        domain_select <= s_axi_wdata[1:0];
                        s_axi_bresp <= 2'b00; // OKAY
                    end
                    default: begin
                        s_axi_bresp <= 2'b10; // SLVERR
                    end
                endcase
            end
        end
    end
    
    // 读通道状态机 - 状态转换逻辑
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            read_state <= IDLE;
        end else begin
            case (read_state)
                IDLE: begin
                    if (s_axi_arvalid) begin
                        read_state <= DATA;
                    end
                end
                
                DATA: begin
                    if (s_axi_rready) begin
                        read_state <= IDLE;
                    end else begin
                        read_state <= RESP;
                    end
                end
                
                RESP: begin
                    if (s_axi_rready) begin
                        read_state <= IDLE;
                    end
                end
                
                default: begin
                    read_state <= IDLE;
                end
            endcase
        end
    end
    
    // 读通道 - 控制信号逻辑
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
        end else begin
            case (read_state)
                IDLE: begin
                    s_axi_arready <= 1'b1;
                    
                    if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b0;
                    end
                end
                
                DATA: begin
                    s_axi_rvalid <= 1'b1;
                    
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        s_axi_arready <= 1'b1;
                    end
                end
                
                RESP: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        s_axi_arready <= 1'b1;
                    end
                end
            endcase
        end
    end
    
    // 读通道 - 数据处理逻辑
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            read_addr <= 32'h0;
            s_axi_rdata <= 32'h0;
            s_axi_rresp <= 2'b00;
        end else begin
            if (read_state == IDLE && s_axi_arvalid) begin
                read_addr <= s_axi_araddr;
            end
            
            if (read_state == IDLE && s_axi_arvalid || read_state == DATA && !s_axi_rvalid) begin
                // 根据地址返回对应寄存器数据
                case (s_axi_araddr[3:0])
                    ADDR_GLOBAL_RST: begin
                        s_axi_rdata <= {31'b0, global_rst};
                        s_axi_rresp <= 2'b00; // OKAY
                    end
                    ADDR_DOMAIN_SELECT: begin
                        s_axi_rdata <= {30'b0, domain_select};
                        s_axi_rresp <= 2'b00; // OKAY
                    end
                    ADDR_SUBSYSTEM_RST: begin
                        s_axi_rdata <= {24'b0, subsystem_rst};
                        s_axi_rresp <= 2'b00; // OKAY
                    end
                    default: begin
                        s_axi_rdata <= 32'h0;
                        s_axi_rresp <= 2'b10; // SLVERR
                    end
                endcase
            end
        end
    end
    
    // 重置分配逻辑
    wire [3:0] domain_rst;
    
    // 域复位逻辑
    assign domain_rst[0] = global_rst;
    assign domain_rst[1] = global_rst;
    assign domain_rst[2] = global_rst & domain_select[0];
    assign domain_rst[3] = global_rst & domain_select[1];
    
    // 子系统复位分配
    assign subsystem_rst[1:0] = {2{domain_rst[0]}};
    assign subsystem_rst[3:2] = {2{domain_rst[1]}};
    assign subsystem_rst[5:4] = {2{domain_rst[2]}};
    assign subsystem_rst[7:6] = {2{domain_rst[3]}};

endmodule