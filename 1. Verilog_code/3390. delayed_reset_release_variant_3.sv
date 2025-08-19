//SystemVerilog
module delayed_reset_release_axi4lite (
    // 全局信号
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite 写地址通道
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    
    // AXI4-Lite 写数据通道
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    
    // AXI4-Lite 写响应通道
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite 读地址通道
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    
    // AXI4-Lite 读数据通道
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // 功能输出
    output reg         reset_out
);

    // 内部寄存器定义
    reg [3:0] delay_value_reg;
    reg [3:0] counter;
    reg       reset_pending;
    
    // 寄存器地址映射 (字对齐)
    localparam ADDR_DELAY_VALUE = 4'h0; // 地址 0x00
    localparam ADDR_RESET_CTRL  = 4'h4; // 地址 0x04
    localparam ADDR_STATUS      = 4'h8; // 地址 0x08
    
    // AXI4-Lite 写事务 - 状态机
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_DATA = 2'b01;
    localparam WRITE_RESP = 2'b10;
    reg [1:0] write_state;
    
    // AXI4-Lite 读事务 - 状态机
    localparam READ_ADDR = 1'b0;
    localparam READ_DATA = 1'b1;
    reg read_state;
    
    // 写地址暂存
    reg [3:0] write_addr;
    
    // 读地址暂存
    reg [3:0] read_addr;
    
    // 复位处理逻辑 - 优化时序性能
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            counter <= 4'h0;
            reset_out <= 1'b0;
            reset_pending <= 1'b0;
        end else begin
            if (reset_pending) begin
                counter <= delay_value_reg;
                reset_out <= 1'b1;
                reset_pending <= 1'b0; // 自动清除挂起状态
            end else if (|counter) begin  // 使用位或操作优化
                counter <= counter - 1'b1;
                reset_out <= 1'b1;
            end else begin
                reset_out <= 1'b0;
            end
        end
    end

    // AXI4-Lite 写地址和数据通道处理 - 优化状态机
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            write_state <= WRITE_IDLE;
            s_axi_awready <= 1'b1;  // 初始状态为就绪，提高吞吐量
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;   // OKAY
            write_addr <= 4'h0;
            delay_value_reg <= 4'h0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    if (s_axi_awvalid && s_axi_awready) begin
                        write_addr <= s_axi_awaddr[5:2];
                        s_axi_awready <= 1'b0;
                        s_axi_wready <= 1'b1;
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        s_axi_wready <= 1'b0;
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp <= 2'b00;  // OKAY
                        
                        // 处理写操作 - 使用case优化
                        case (write_addr)
                            ADDR_DELAY_VALUE[3:0]: begin
                                if (s_axi_wstrb[0]) delay_value_reg <= s_axi_wdata[3:0];
                            end
                            ADDR_RESET_CTRL[3:0]: begin
                                if (s_axi_wstrb[0]) reset_pending <= s_axi_wdata[0];
                            end
                        endcase
                        
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axi_bready && s_axi_bvalid) begin
                        s_axi_bvalid <= 1'b0;
                        s_axi_awready <= 1'b1;  // 准备接收下一个请求
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: begin
                    write_state <= WRITE_IDLE;
                end
            endcase
        end
    end
    
    // AXI4-Lite 读通道处理 - 简化状态机，提高响应速度
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            read_state <= READ_ADDR;
            s_axi_arready <= 1'b1;  // 初始状态为就绪
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;   // OKAY
            read_addr <= 4'h0;
        end else begin
            case (read_state)
                READ_ADDR: begin
                    if (s_axi_arvalid && s_axi_arready) begin
                        read_addr <= s_axi_araddr[5:2];
                        s_axi_arready <= 1'b0;
                        s_axi_rvalid <= 1'b1;
                        s_axi_rresp <= 2'b00;  // OKAY
                        
                        // 根据地址提供读取数据 - 优化数据路径
                        case (read_addr)
                            ADDR_DELAY_VALUE[3:0]: s_axi_rdata <= {28'h0, delay_value_reg};
                            ADDR_RESET_CTRL[3:0]:  s_axi_rdata <= {31'h0, reset_pending};
                            ADDR_STATUS[3:0]:      s_axi_rdata <= {27'h0, reset_out, counter};
                            default:               s_axi_rdata <= 32'h0;
                        endcase
                        
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    if (s_axi_rready && s_axi_rvalid) begin
                        s_axi_rvalid <= 1'b0;
                        s_axi_arready <= 1'b1;  // 准备接收下一个请求
                        read_state <= READ_ADDR;
                    end
                end
            endcase
        end
    end

endmodule