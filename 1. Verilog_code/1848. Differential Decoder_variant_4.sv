//SystemVerilog
module differential_decoder_axi (
    // 全局信号
    input  wire         s_axi_aclk,
    input  wire         s_axi_aresetn,
    
    // AXI4-Lite 写地址通道
    input  wire [31:0]  s_axi_awaddr,
    input  wire [2:0]   s_axi_awprot,
    input  wire         s_axi_awvalid,
    output wire         s_axi_awready,
    
    // AXI4-Lite 写数据通道
    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output wire         s_axi_wready,
    
    // AXI4-Lite 写响应通道
    output wire [1:0]   s_axi_bresp,
    output wire         s_axi_bvalid,
    input  wire         s_axi_bready,
    
    // AXI4-Lite 读地址通道
    input  wire [31:0]  s_axi_araddr,
    input  wire [2:0]   s_axi_arprot,
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,
    
    // AXI4-Lite 读数据通道
    output wire [31:0]  s_axi_rdata,
    output wire [1:0]   s_axi_rresp,
    output wire         s_axi_rvalid,
    input  wire         s_axi_rready,
    
    // 差分输入信号
    input  wire         diff_in
);

    // 寄存器映射 (字地址)
    localparam ADDR_CONTROL     = 4'h0;  // 控制寄存器
    localparam ADDR_STATUS      = 4'h4;  // 状态寄存器

    // 内部信号
    reg         decoded_out;
    wire        parity_error;
    reg         prev_diff_in;
    reg         parity_bit;
    reg  [2:0]  bit_counter;
    reg         expected_parity;
    
    // AXI4-Lite 接口实现
    reg  [31:0] axi_awaddr;
    reg         axi_awready;
    reg         axi_wready;
    reg  [1:0]  axi_bresp;
    reg         axi_bvalid;
    reg  [31:0] axi_araddr;
    reg         axi_arready;
    reg  [31:0] axi_rdata;
    reg  [1:0]  axi_rresp;
    reg         axi_rvalid;
    
    // 寄存器
    reg  [31:0] control_reg;
    wire        decoder_enable;
    
    // 高扇出信号缓冲寄存器
    reg  [31:0] s_axi_wdata_buf;
    reg  [3:0]  s_axi_wstrb_buf;
    reg  [31:0] axi_awaddr_buf;
    reg  [2:0]  bit_counter_buf;
    reg         h0_buf;
    
    // 映射到输出端口
    assign s_axi_awready = axi_awready;
    assign s_axi_wready  = axi_wready;
    assign s_axi_bresp   = axi_bresp;
    assign s_axi_bvalid  = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata   = axi_rdata;
    assign s_axi_rresp   = axi_rresp;
    assign s_axi_rvalid  = axi_rvalid;
    
    // 控制寄存器位
    assign decoder_enable = control_reg[0];
    
    // 高扇出信号缓冲
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_wdata_buf <= 32'h0;
            s_axi_wstrb_buf <= 4'h0;
            axi_awaddr_buf <= 32'h0;
            bit_counter_buf <= 3'h0;
            h0_buf <= 1'b0;
        end else begin
            s_axi_wdata_buf <= s_axi_wdata;
            s_axi_wstrb_buf <= s_axi_wstrb;
            axi_awaddr_buf <= axi_awaddr;
            bit_counter_buf <= bit_counter;
            h0_buf <= decoded_out;
        end
    end
    
    // 写地址握手
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_awready <= 1'b0;
            axi_awaddr  <= 32'b0;
        end else begin
            if (~axi_awready && s_axi_awvalid && s_axi_wvalid) begin
                axi_awready <= 1'b1;
                axi_awaddr  <= s_axi_awaddr;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end
    
    // 写数据握手
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && s_axi_wvalid && s_axi_awvalid) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end
    
    // 写响应
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_bvalid <= 1'b0;
            axi_bresp  <= 2'b0;
        end else begin
            if (axi_awready && s_axi_awvalid && ~axi_bvalid && axi_wready && s_axi_wvalid) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b00; // OKAY响应
            end else begin
                if (s_axi_bready && axi_bvalid) begin
                    axi_bvalid <= 1'b0;
                end
            end
        end
    end
    
    // 写入寄存器
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            control_reg <= 32'h0;
        end else begin
            if (axi_wready && s_axi_wvalid && axi_awready && s_axi_awvalid) begin
                case (axi_awaddr_buf[7:0] & 32'hFC)
                    ADDR_CONTROL: begin
                        if (s_axi_wstrb_buf[0]) control_reg[7:0]   <= s_axi_wdata_buf[7:0];
                        if (s_axi_wstrb_buf[1]) control_reg[15:8]  <= s_axi_wdata_buf[15:8];
                        if (s_axi_wstrb_buf[2]) control_reg[23:16] <= s_axi_wdata_buf[23:16];
                        if (s_axi_wstrb_buf[3]) control_reg[31:24] <= s_axi_wdata_buf[31:24];
                    end
                    default: begin
                    end
                endcase
            end
        end
    end
    
    // 读地址握手
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 32'b0;
        end else begin
            if (~axi_arready && s_axi_arvalid) begin
                axi_arready <= 1'b1;
                axi_araddr  <= s_axi_araddr;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end
    
    // 读数据和响应
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b0;
        end else begin
            if (axi_arready && s_axi_arvalid && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b00; // OKAY响应
            end else if (axi_rvalid && s_axi_rready) begin
                axi_rvalid <= 1'b0;
            end
        end
    end
    
    // 读寄存器数据
    always @(*) begin
        axi_rdata = 32'h0;
        
        if (axi_arready && s_axi_arvalid && ~axi_rvalid) begin
            case (axi_araddr[7:0] & 32'hFC)
                ADDR_CONTROL: begin
                    axi_rdata = control_reg;
                end
                ADDR_STATUS: begin
                    axi_rdata = {29'h0, parity_error, h0_buf, 1'b0};
                end
                default: begin
                    axi_rdata = 32'h0;
                end
            endcase
        end
    end
    
    // 原差分解码器核心逻辑
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            prev_diff_in <= 1'b0;
            decoded_out <= 1'b0;
            parity_bit <= 1'b0;
        end else if (decoder_enable) begin
            prev_diff_in <= diff_in;
            decoded_out <= diff_in ^ prev_diff_in;
            parity_bit <= parity_bit ^ decoded_out;
        end
    end
    
    // 简单的错误检测逻辑
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            bit_counter <= 3'b000;
            expected_parity <= 1'b0;
        end else if (decoder_enable) begin
            bit_counter <= bit_counter + 1'b1;
            
            if (bit_counter_buf == 3'b111)
                expected_parity <= ~expected_parity;
        end
    end
    
    assign parity_error = (bit_counter_buf == 3'b000) ? (parity_bit != expected_parity) : 1'b0;

endmodule