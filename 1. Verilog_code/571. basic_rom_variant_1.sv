//SystemVerilog
module basic_rom_axi (
    // 全局接口信号
    input wire         aclk,
    input wire         aresetn,
    
    // AXI4-Lite 写地址通道
    input wire [7:0]   s_axil_awaddr,
    input wire [2:0]   s_axil_awprot,
    input wire         s_axil_awvalid,
    output reg         s_axil_awready,
    
    // AXI4-Lite 写数据通道
    input wire [31:0]  s_axil_wdata,
    input wire [3:0]   s_axil_wstrb,
    input wire         s_axil_wvalid,
    output reg         s_axil_wready,
    
    // AXI4-Lite 写响应通道
    output reg [1:0]   s_axil_bresp,
    output reg         s_axil_bvalid,
    input wire         s_axil_bready,
    
    // AXI4-Lite 读地址通道
    input wire [7:0]   s_axil_araddr,
    input wire [2:0]   s_axil_arprot,
    input wire         s_axil_arvalid,
    output reg         s_axil_arready,
    
    // AXI4-Lite 读数据通道
    output reg [31:0]  s_axil_rdata,
    output reg [1:0]   s_axil_rresp,
    output reg         s_axil_rvalid,
    input wire         s_axil_rready
);
    
    // 定义ROM内容存储
    reg [7:0] rom_data [0:15];
    
    // 内部信号
    reg [3:0] read_addr;
    reg read_valid;
    
    // 初始化ROM数据
    initial begin
        rom_data[4'h0] = 8'h12;
        rom_data[4'h1] = 8'h34;
        rom_data[4'h2] = 8'h56;
        rom_data[4'h3] = 8'h78;
        rom_data[4'h4] = 8'h9A;
        rom_data[4'h5] = 8'hBC;
        rom_data[4'h6] = 8'hDE;
        rom_data[4'h7] = 8'hF0;
        rom_data[4'h8] = 8'h00;
        rom_data[4'h9] = 8'h00;
        rom_data[4'hA] = 8'h00;
        rom_data[4'hB] = 8'h00;
        rom_data[4'hC] = 8'h00;
        rom_data[4'hD] = 8'h00;
        rom_data[4'hE] = 8'h00;
        rom_data[4'hF] = 8'h00;
    end
    
    // 读地址通道处理
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_arready <= 1'b0;
            read_addr <= 4'h0;
            read_valid <= 1'b0;
        end else begin
            if (s_axil_arvalid && !s_axil_arready) begin
                s_axil_arready <= 1'b1;
                read_addr <= s_axil_araddr[5:2]; // 按字对齐，对应ROM的地址
                read_valid <= 1'b1;
            end else begin
                s_axil_arready <= 1'b0;
                if (s_axil_rready && s_axil_rvalid) begin
                    read_valid <= 1'b0;
                end
            end
        end
    end
    
    // 读数据通道处理
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= 2'b0;
        end else begin
            if (read_valid && !s_axil_rvalid) begin
                s_axil_rvalid <= 1'b1;
                s_axil_rresp <= 2'b00; // OKAY响应
                // 32位数据，低8位放ROM数据，高位补0
                s_axil_rdata <= {24'b0, rom_data[read_addr]};
            end else if (s_axil_rready && s_axil_rvalid) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end
    
    // 写地址通道处理 - ROM不支持写入，但需要响应
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready <= 1'b0;
        end else begin
            if (s_axil_awvalid && !s_axil_awready) begin
                s_axil_awready <= 1'b1;
            end else begin
                s_axil_awready <= 1'b0;
            end
        end
    end
    
    // 写数据通道处理 - ROM不支持写入，但需要响应
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_wready <= 1'b0;
        end else begin
            if (s_axil_wvalid && !s_axil_wready) begin
                s_axil_wready <= 1'b1;
            end else begin
                s_axil_wready <= 1'b0;
            end
        end
    end
    
    // 写响应通道处理 - 返回错误响应，因为ROM不可写
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
        end else begin
            if (s_axil_awready && s_axil_wready && !s_axil_bvalid) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp <= 2'b10; // SLVERR - 从机错误，表示不支持写操作
            end else if (s_axil_bready && s_axil_bvalid) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end

endmodule