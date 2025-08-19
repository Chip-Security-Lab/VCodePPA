//SystemVerilog
module d_ff_async_reset_axi (
    // 全局信号
    input  wire        axi_aclk,          // AXI时钟信号
    input  wire        axi_aresetn,       // AXI低电平有效的异步复位
    
    // AXI4-Lite写地址通道
    input  wire [31:0] s_axi_awaddr,      // 写地址
    input  wire        s_axi_awvalid,     // 写地址有效
    output reg         s_axi_awready,     // 写地址就绪
    
    // AXI4-Lite写数据通道
    input  wire [31:0] s_axi_wdata,       // 写数据
    input  wire [3:0]  s_axi_wstrb,       // 写选通
    input  wire        s_axi_wvalid,      // 写数据有效
    output reg         s_axi_wready,      // 写数据就绪
    
    // AXI4-Lite写响应通道
    output reg [1:0]   s_axi_bresp,       // 写响应
    output reg         s_axi_bvalid,      // 写响应有效
    input  wire        s_axi_bready,      // 写响应就绪
    
    // AXI4-Lite读地址通道
    input  wire [31:0] s_axi_araddr,      // 读地址
    input  wire        s_axi_arvalid,     // 读地址有效
    output reg         s_axi_arready,     // 读地址就绪
    
    // AXI4-Lite读数据通道
    output reg [31:0]  s_axi_rdata,       // 读数据
    output reg [1:0]   s_axi_rresp,       // 读响应
    output reg         s_axi_rvalid,      // 读数据有效
    input  wire        s_axi_rready       // 读数据就绪
);

    // 参数定义
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam ADDR_LSB = 2;  // 字节寻址到字寻址
    localparam REG_ADDR_0 = 0; // 寄存器地址0: 数据输入寄存器
    localparam REG_ADDR_1 = 4; // 寄存器地址1: 数据输出寄存器
    
    // AXI响应类型
    localparam RESP_OKAY = 2'b00;    // 成功
    localparam RESP_ERROR = 2'b10;   // 错误
    
    // 内部信号定义
    reg  d_reg;           // 数据输入寄存器
    reg  d_pipeline;      // 输入数据的流水线寄存器
    reg  q_reg;           // 数据输出寄存器
    
    // AXI状态机状态
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;
    localparam RESP = 2'b11;
    reg [1:0] write_state, read_state;
    
    // 写操作内部地址
    reg [ADDR_WIDTH-1:0] write_addr;
    
    // 读操作内部地址
    reg [ADDR_WIDTH-1:0] read_addr;
    
    // 写地址通道处理
    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            s_axi_awready <= 1'b0;
            write_addr <= {ADDR_WIDTH{1'b0}};
            write_state <= IDLE;
        end else begin
            case (write_state)
                IDLE: begin
                    if (s_axi_awvalid && !s_axi_awready) begin
                        s_axi_awready <= 1'b1;
                        write_addr <= s_axi_awaddr;
                        write_state <= ADDR;
                    end
                end
                ADDR: begin
                    s_axi_awready <= 1'b0;
                    write_state <= DATA;
                end
                DATA: begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        write_state <= RESP;
                    end
                end
                RESP: begin
                    if (s_axi_bready && s_axi_bvalid) begin
                        write_state <= IDLE;
                    end
                end
                default: write_state <= IDLE;
            endcase
        end
    end
    
    // 写数据通道处理
    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            s_axi_wready <= 1'b0;
            d_reg <= 1'b0;
        end else begin
            if (write_state == DATA && !s_axi_wready) begin
                s_axi_wready <= 1'b1;
            end else if (s_axi_wvalid && s_axi_wready) begin
                s_axi_wready <= 1'b0;
                
                // 寄存器写操作
                case (write_addr[ADDR_LSB+:2])
                    REG_ADDR_0[ADDR_LSB+:2]: begin
                        if (s_axi_wstrb[0]) d_reg <= s_axi_wdata[0]; // 只写第0位
                    end
                    default: begin
                        // 其他地址无效，不执行写操作
                    end
                endcase
            end
        end
    end
    
    // 写响应通道处理
    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= RESP_OKAY;
        end else begin
            if (s_axi_wvalid && s_axi_wready && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                // 判断地址是否有效
                if (write_addr[ADDR_LSB+:2] == REG_ADDR_0[ADDR_LSB+:2]) begin
                    s_axi_bresp <= RESP_OKAY;
                end else begin
                    s_axi_bresp <= RESP_ERROR;
                end
            end else if (s_axi_bready && s_axi_bvalid) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end
    
    // 读地址通道处理
    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            s_axi_arready <= 1'b0;
            read_addr <= {ADDR_WIDTH{1'b0}};
            read_state <= IDLE;
        end else begin
            case (read_state)
                IDLE: begin
                    if (s_axi_arvalid && !s_axi_arready) begin
                        s_axi_arready <= 1'b1;
                        read_addr <= s_axi_araddr;
                        read_state <= ADDR;
                    end
                end
                ADDR: begin
                    s_axi_arready <= 1'b0;
                    read_state <= DATA;
                end
                DATA: begin
                    if (s_axi_rvalid && s_axi_rready) begin
                        read_state <= IDLE;
                    end
                end
                default: read_state <= IDLE;
            endcase
        end
    end
    
    // 读数据通道处理
    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= {DATA_WIDTH{1'b0}};
            s_axi_rresp <= RESP_OKAY;
        end else begin
            if (read_state == DATA && !s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                
                // 寄存器读操作
                case (read_addr[ADDR_LSB+:2])
                    REG_ADDR_0[ADDR_LSB+:2]: begin
                        s_axi_rdata <= {{DATA_WIDTH-1{1'b0}}, d_reg};
                        s_axi_rresp <= RESP_OKAY;
                    end
                    REG_ADDR_1[ADDR_LSB+:2]: begin
                        s_axi_rdata <= {{DATA_WIDTH-1{1'b0}}, q_reg};
                        s_axi_rresp <= RESP_OKAY;
                    end
                    default: begin
                        s_axi_rdata <= {DATA_WIDTH{1'b0}};
                        s_axi_rresp <= RESP_ERROR;
                    end
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
    
    // 输入数据流水线级
    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            d_pipeline <= 1'b0;  // 异步复位
        end else begin
            d_pipeline <= d_reg; // 第一级流水线
        end
    end
    
    // 输出数据流水线级
    always @(posedge axi_aclk or negedge axi_aresetn) begin
        if (!axi_aresetn) begin
            q_reg <= 1'b0;           // 异步复位
        end else begin
            q_reg <= d_pipeline;     // 第二级流水线
        end
    end

endmodule