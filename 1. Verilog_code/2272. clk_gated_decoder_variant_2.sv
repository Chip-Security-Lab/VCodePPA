//SystemVerilog
module clk_gated_decoder(
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite 写地址通道
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_awaddr,
    input  wire [2:0]  s_axi_awprot,
    
    // AXI4-Lite 写数据通道
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    
    // AXI4-Lite 写响应通道
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    output wire [1:0]  s_axi_bresp,
    
    // AXI4-Lite 读地址通道
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    input  wire [31:0] s_axi_araddr,
    input  wire [2:0]  s_axi_arprot,
    
    // AXI4-Lite 读数据通道
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    
    // 解码器输出
    output reg  [7:0]  select
);

    // AXI4-Lite 常量定义
    localparam RESP_OKAY = 2'b00;
    localparam ADDR_CONTROL = 4'h0;
    localparam ADDR_STATUS = 4'h4;
    
    // 内部寄存器
    reg [2:0]  addr_reg;
    reg        enable_reg;
    reg        valid_in_reg;
    reg        valid_out_reg;
    
    // 流水线寄存器
    reg [2:0]  addr_stage1;
    reg        enable_stage1;
    reg        valid_stage1;
    
    reg [4:0]  decode_stage2;
    reg        valid_stage2;
    
    // AXI4-Lite 接口控制寄存器
    reg        axi_awready;
    reg        axi_wready;
    reg        axi_bvalid;
    reg        axi_arready;
    reg        axi_rvalid;
    reg [31:0] axi_rdata;
    
    // 写地址就绪信号
    assign s_axi_awready = axi_awready;
    // 写数据就绪信号
    assign s_axi_wready = axi_wready;
    // 写响应有效信号
    assign s_axi_bvalid = axi_bvalid;
    // 写响应状态
    assign s_axi_bresp = RESP_OKAY;
    
    // 读地址就绪信号
    assign s_axi_arready = axi_arready;
    // 读数据有效信号
    assign s_axi_rvalid = axi_rvalid;
    // 读数据响应
    assign s_axi_rresp = RESP_OKAY;
    // 读数据
    assign s_axi_rdata = axi_rdata;
    
    // 写地址通道握手
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_awready <= 1'b0;
        end else begin
            if (~axi_awready && s_axi_awvalid) begin
                axi_awready <= 1'b1;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end
    
    // 写数据通道握手
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && s_axi_wvalid) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end
    
    // 写响应通道握手
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_bvalid <= 1'b0;
        end else begin
            if (axi_wready && s_axi_wvalid && ~axi_bvalid && axi_awready && s_axi_awvalid) begin
                axi_bvalid <= 1'b1;
            end else if (s_axi_bready && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end
    
    // 读地址通道握手
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_arready <= 1'b0;
        end else begin
            if (~axi_arready && s_axi_arvalid) begin
                axi_arready <= 1'b1;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end
    
    // 读数据通道握手和数据返回
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_rvalid <= 1'b0;
            axi_rdata <= 32'b0;
        end else begin
            if (axi_arready && s_axi_arvalid && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                case (s_axi_araddr[3:0])
                    ADDR_CONTROL: axi_rdata <= {29'b0, addr_reg};
                    ADDR_STATUS: axi_rdata <= {23'b0, select, valid_out_reg};
                    default: axi_rdata <= 32'b0;
                endcase
            end else if (axi_rvalid && s_axi_rready) begin
                axi_rvalid <= 1'b0;
            end
        end
    end
    
    // 寄存器写入逻辑
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            addr_reg <= 3'b000;
            enable_reg <= 1'b0;
            valid_in_reg <= 1'b0;
        end else begin
            if (axi_awready && s_axi_awvalid && axi_wready && s_axi_wvalid) begin
                case (s_axi_awaddr[3:0])
                    ADDR_CONTROL: begin
                        if (s_axi_wstrb[0]) begin
                            addr_reg <= s_axi_wdata[2:0];
                            enable_reg <= s_axi_wdata[3];
                            valid_in_reg <= s_axi_wdata[4];
                        end
                    end
                    default: begin
                        // 其他地址不处理
                    end
                endcase
            end
        end
    end
    
    // 第一级流水线 - 寄存输入
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            addr_stage1 <= 3'b000;
            enable_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr_reg;
            enable_stage1 <= enable_reg;
            valid_stage1 <= valid_in_reg;
        end
    end
    
    // 第二级流水线 - 预解码
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            decode_stage2 <= 5'b00000;
            valid_stage2 <= 1'b0;
        end else begin
            // 预解码部分计算
            decode_stage2 <= {addr_stage1, enable_stage1, valid_stage1};
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 最终解码和输出
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            select <= 8'b00000000;
            valid_out_reg <= 1'b0;
        end else begin
            if (decode_stage2[1] && valid_stage2) begin // enable和valid都有效
                select <= (8'b00000001 << decode_stage2[4:2]);
            end else begin
                select <= 8'b00000000;
            end
            valid_out_reg <= valid_stage2 && decode_stage2[1]; // 传递有效信号
        end
    end

endmodule