//SystemVerilog
module gamma_correction_codec (
    // Global signals
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input wire [31:0] s_axi_awaddr,
    input wire [2:0] s_axi_awprot,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] s_axi_araddr,
    input wire [2:0] s_axi_arprot,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready
);

    // 寄存器地址映射 (字节地址)
    localparam ADDR_CTRL       = 4'h0;    // 控制寄存器: bit0=enable, bit1=reset
    localparam ADDR_GAMMA      = 4'h4;    // Gamma因子寄存器
    localparam ADDR_PIXEL_IN   = 4'h8;    // 输入像素寄存器
    localparam ADDR_PIXEL_OUT  = 4'hC;    // 输出像素寄存器

    // 内部寄存器
    reg enable;
    reg reset;
    reg [2:0] gamma_factor;
    reg [7:0] pixel_in;
    reg [7:0] pixel_out;
    
    // 写地址通道信号
    reg [3:0] axi_awaddr;
    reg write_addr_valid;
    
    // 读地址通道信号
    reg [3:0] axi_araddr;
    
    // Gamma查找表
    reg [15:0] gamma_lut [0:7][0:255];
    integer g, i;
    
    // 初始化查找表和寄存器
    initial begin
        for (g = 0; g < 8; g = g + 1)
            for (i = 0; i < 256; i = i + 1)
                gamma_lut[g][i] = i * (g + 1);
        
        // 初始化AXI4-Lite信号
        s_axi_awready = 1'b0;
        s_axi_wready = 1'b0;
        s_axi_bresp = 2'b00;
        s_axi_bvalid = 1'b0;
        s_axi_arready = 1'b0;
        s_axi_rdata = 32'h0;
        s_axi_rresp = 2'b00;
        s_axi_rvalid = 1'b0;
        
        // 初始化内部寄存器
        enable = 1'b0;
        reset = 1'b0;
        gamma_factor = 3'b000;
        pixel_in = 8'h00;
        pixel_out = 8'h00;
    end
    
    // AXI4-Lite写地址通道处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            write_addr_valid <= 1'b0;
            axi_awaddr <= 4'h0;
        end
        else begin
            if (~s_axi_awready && s_axi_awvalid && ~write_addr_valid) begin
                s_axi_awready <= 1'b1;
                axi_awaddr <= s_axi_awaddr[3:0];
                write_addr_valid <= 1'b1;
            end
            else if (s_axi_wready && s_axi_wvalid) begin
                write_addr_valid <= 1'b0;
                s_axi_awready <= 1'b0;
            end
            else begin
                s_axi_awready <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite写数据通道处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
        end
        else begin
            if (~s_axi_wready && s_axi_wvalid && write_addr_valid) begin
                s_axi_wready <= 1'b1;
            end
            else begin
                s_axi_wready <= 1'b0;
            end
        end
    end
    
    // 写响应通道处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
        end
        else begin
            if (s_axi_wready && s_axi_wvalid && ~s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00;  // OKAY响应
            end
            else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end
    
    // 控制寄存器写入处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            enable <= 1'b0;
            reset <= 1'b0;
        end
        else if (s_axi_wready && s_axi_wvalid && axi_awaddr == ADDR_CTRL && s_axi_wstrb[0]) begin
            enable <= s_axi_wdata[0];
            reset <= s_axi_wdata[1];
        end
    end
    
    // Gamma因子寄存器写入处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            gamma_factor <= 3'b000;
        end
        else if (s_axi_wready && s_axi_wvalid && axi_awaddr == ADDR_GAMMA && s_axi_wstrb[0]) begin
            gamma_factor <= s_axi_wdata[2:0];
        end
    end
    
    // 像素输入寄存器写入处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            pixel_in <= 8'h00;
        end
        else if (s_axi_wready && s_axi_wvalid && axi_awaddr == ADDR_PIXEL_IN && s_axi_wstrb[0]) begin
            pixel_in <= s_axi_wdata[7:0];
        end
    end
    
    // Gamma校正核心处理逻辑
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            pixel_out <= 8'h00;
        end
        else if (reset) begin
            pixel_out <= 8'd0;
        end
        else if (enable) begin
            pixel_out <= gamma_lut[gamma_factor][pixel_in][7:0];
        end
    end
    
    // AXI4-Lite读地址通道处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            axi_araddr <= 4'h0;
        end
        else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                axi_araddr <= s_axi_araddr[3:0];
            end
            else begin
                s_axi_arready <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite读数据通道处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            s_axi_rdata <= 32'h0;
        end
        else begin
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00;  // OKAY响应
                
                case (axi_araddr)
                    ADDR_CTRL: 
                        s_axi_rdata <= {30'h0, reset, enable};
                    ADDR_GAMMA: 
                        s_axi_rdata <= {29'h0, gamma_factor};
                    ADDR_PIXEL_IN: 
                        s_axi_rdata <= {24'h0, pixel_in};
                    ADDR_PIXEL_OUT: 
                        s_axi_rdata <= {24'h0, pixel_out};
                    default: 
                        s_axi_rdata <= 32'h0;
                endcase
            end
            else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule