//SystemVerilog - IEEE 1364-2005
module decoder_dual_port_axi4lite (
    // AXI4-Lite接口信号
    input wire         s_axi_aclk,
    input wire         s_axi_aresetn,
    // 写地址通道
    input wire [31:0]  s_axi_awaddr,
    input wire         s_axi_awvalid,
    output reg         s_axi_awready,
    // 写数据通道  
    input wire [31:0]  s_axi_wdata,
    input wire [3:0]   s_axi_wstrb,
    input wire         s_axi_wvalid, 
    output reg         s_axi_wready,
    // 写响应通道
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input wire         s_axi_bready,
    // 读地址通道
    input wire [31:0]  s_axi_araddr,
    input wire         s_axi_arvalid,
    output reg         s_axi_arready,
    // 读数据通道
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input wire         s_axi_rready,
    
    // 原始模块输出
    output wire [15:0] rd_sel,
    output wire [15:0] wr_sel
);

    // 内部寄存器
    reg [3:0] rd_addr_reg;
    reg [3:0] wr_addr_reg;
    
    // 输入寄存器 - 前向寄存器重定时
    reg [31:0] s_axi_awaddr_reg;
    reg        s_axi_awvalid_reg;
    reg [31:0] s_axi_wdata_reg;
    reg [3:0]  s_axi_wstrb_reg;
    reg        s_axi_wvalid_reg;
    reg        s_axi_bready_reg;
    reg [31:0] s_axi_araddr_reg;
    reg        s_axi_arvalid_reg;
    reg        s_axi_rready_reg;
    
    // 状态机状态定义
    localparam IDLE = 2'b00;
    localparam W_ADDR = 2'b01;
    localparam W_DATA = 2'b10;
    localparam W_RESP = 2'b11;
    
    localparam R_ADDR = 2'b01;
    localparam R_DATA = 2'b10;
    
    reg [1:0] write_state, write_next;
    reg [1:0] read_state, read_next;
    
    // 地址偏移定义
    localparam ADDR_RD_ADDR = 4'h0;  // 0x00: rd_addr寄存器
    localparam ADDR_WR_ADDR = 4'h4;  // 0x04: wr_addr寄存器
    localparam ADDR_RD_SEL = 4'h8;   // 0x08: rd_sel输出(只读)
    localparam ADDR_WR_SEL = 4'hC;   // 0x0C: wr_sel输出(只读)
    
    // 对输入信号进行寄存 - 前向寄存器重定时
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awaddr_reg  <= 32'h0;
            s_axi_awvalid_reg <= 1'b0;
            s_axi_wdata_reg   <= 32'h0;
            s_axi_wstrb_reg   <= 4'h0;
            s_axi_wvalid_reg  <= 1'b0;
            s_axi_bready_reg  <= 1'b0;
            s_axi_araddr_reg  <= 32'h0;
            s_axi_arvalid_reg <= 1'b0;
            s_axi_rready_reg  <= 1'b0;
        end else begin
            s_axi_awaddr_reg  <= s_axi_awaddr;
            s_axi_awvalid_reg <= s_axi_awvalid;
            s_axi_wdata_reg   <= s_axi_wdata;
            s_axi_wstrb_reg   <= s_axi_wstrb;
            s_axi_wvalid_reg  <= s_axi_wvalid;
            s_axi_bready_reg  <= s_axi_bready;
            s_axi_araddr_reg  <= s_axi_araddr;
            s_axi_arvalid_reg <= s_axi_arvalid;
            s_axi_rready_reg  <= s_axi_rready;
        end
    end

    // 实现原始模块功能
    assign rd_sel = 1'b1 << rd_addr_reg;
    assign wr_sel = 1'b1 << wr_addr_reg;
    
    // 写状态机 - 使用寄存的输入信号
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            write_state <= IDLE;
        end else begin
            write_state <= write_next;
        end
    end
    
    always @(*) begin
        write_next = write_state;
        
        case (write_state)
            IDLE: begin
                if (s_axi_awvalid_reg)
                    write_next = W_ADDR;
            end
            
            W_ADDR: begin
                if (s_axi_awready && s_axi_awvalid_reg)
                    write_next = W_DATA;
            end
            
            W_DATA: begin
                if (s_axi_wready && s_axi_wvalid_reg)
                    write_next = W_RESP;
            end
            
            W_RESP: begin
                if (s_axi_bready_reg && s_axi_bvalid)
                    write_next = IDLE;
            end
            
            default: write_next = IDLE;
        endcase
    end
    
    // 写通道控制 - 使用寄存的输入信号
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            rd_addr_reg <= 4'b0000;
            wr_addr_reg <= 4'b0000;
        end else begin
            case (write_state)
                IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready <= 1'b0;
                    s_axi_bvalid <= 1'b0;
                end
                
                W_ADDR: begin
                    if (s_axi_awready && s_axi_awvalid_reg) begin
                        s_axi_awready <= 1'b0;
                        s_axi_wready <= 1'b1;
                    end
                end
                
                W_DATA: begin
                    if (s_axi_wready && s_axi_wvalid_reg) begin
                        s_axi_wready <= 1'b0;
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp <= 2'b00; // OKAY响应
                        
                        case (s_axi_awaddr_reg[3:0])
                            ADDR_RD_ADDR: rd_addr_reg <= s_axi_wdata_reg[3:0];
                            ADDR_WR_ADDR: wr_addr_reg <= s_axi_wdata_reg[3:0];
                            default: s_axi_bresp <= 2'b10; // SLVERR响应
                        endcase
                    end
                end
                
                W_RESP: begin
                    if (s_axi_bready_reg && s_axi_bvalid) begin
                        s_axi_bvalid <= 1'b0;
                    end
                end
            endcase
        end
    end
    
    // 读状态机 - 使用寄存的输入信号
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            read_state <= IDLE;
        end else begin
            read_state <= read_next;
        end
    end
    
    always @(*) begin
        read_next = read_state;
        
        case (read_state)
            IDLE: begin
                if (s_axi_arvalid_reg)
                    read_next = R_ADDR;
            end
            
            R_ADDR: begin
                if (s_axi_arready && s_axi_arvalid_reg)
                    read_next = R_DATA;
            end
            
            R_DATA: begin
                if (s_axi_rready_reg && s_axi_rvalid)
                    read_next = IDLE;
            end
            
            default: read_next = IDLE;
        endcase
    end
    
    // 读通道控制 - 使用寄存的输入信号
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            s_axi_rdata <= 32'h00000000;
        end else begin
            case (read_state)
                IDLE: begin
                    s_axi_arready <= 1'b1;
                    s_axi_rvalid <= 1'b0;
                end
                
                R_ADDR: begin
                    if (s_axi_arready && s_axi_arvalid_reg) begin
                        s_axi_arready <= 1'b0;
                        s_axi_rvalid <= 1'b1;
                        s_axi_rresp <= 2'b00; // OKAY响应
                        
                        case (s_axi_araddr_reg[3:0])
                            ADDR_RD_ADDR: s_axi_rdata <= {28'h0, rd_addr_reg};
                            ADDR_WR_ADDR: s_axi_rdata <= {28'h0, wr_addr_reg};
                            ADDR_RD_SEL:  s_axi_rdata <= {16'h0, rd_sel};
                            ADDR_WR_SEL:  s_axi_rdata <= {16'h0, wr_sel};
                            default: begin
                                s_axi_rdata <= 32'h00000000;
                                s_axi_rresp <= 2'b10; // SLVERR响应
                            end
                        endcase
                    end
                end
                
                R_DATA: begin
                    if (s_axi_rready_reg && s_axi_rvalid) begin
                        s_axi_rvalid <= 1'b0;
                    end
                end
            endcase
        end
    end

endmodule