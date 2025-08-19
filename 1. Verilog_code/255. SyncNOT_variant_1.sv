//SystemVerilog
module SyncNOT_AXI(
    // Global Signals
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input  wire [7:0]  s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input  wire [7:0]  s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    // 内部寄存器
    reg [15:0] async_in_reg;     // 存储输入数据
    reg [15:0] synced_not_reg;   // 存储反转后的结果
    
    // 预先计算下个状态和控制信号，减少关键路径
    reg [1:0] write_next_state;
    reg [1:0] read_next_state;
    reg       awready_next;
    reg       wready_next;
    reg       bvalid_next;
    reg [1:0] bresp_next;
    reg       arready_next;
    reg       rvalid_next;
    reg [1:0] rresp_next;
    reg [31:0] rdata_next;
    
    // 写状态机状态
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    reg [1:0] write_state;
    
    // 读状态机状态
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    reg [1:0] read_state;
    
    // 寄存器地址映射
    localparam ASYNC_IN_ADDR     = 8'h00;  // 输入寄存器地址
    localparam SYNCED_NOT_ADDR   = 8'h04;  // 输出寄存器地址
    
    // AXI4-Lite响应代码
    localparam RESP_OKAY   = 2'b00;  // 成功
    localparam RESP_SLVERR = 2'b10;  // 从机错误
    
    // 将地址对比逻辑分解为更简单的条件
    wire is_async_in_addr = (s_axi_awaddr == ASYNC_IN_ADDR);
    wire is_read_async_in_addr = (s_axi_araddr == ASYNC_IN_ADDR);
    wire is_read_synced_not_addr = (s_axi_araddr == SYNCED_NOT_ADDR);
    
    // 写状态机 - 组合逻辑部分
    always @(*) begin
        // 默认保持当前状态
        write_next_state = write_state;
        awready_next = s_axi_awready;
        wready_next = s_axi_wready;
        bvalid_next = s_axi_bvalid;
        bresp_next = s_axi_bresp;
        
        case (write_state)
            WRITE_IDLE: begin
                awready_next = 1'b1;
                if (s_axi_awvalid && s_axi_awready) begin
                    write_next_state = WRITE_DATA;
                    awready_next = 1'b0;
                    wready_next = 1'b1;
                end
            end
            
            WRITE_DATA: begin
                if (s_axi_wvalid && s_axi_wready) begin
                    write_next_state = WRITE_RESP;
                    wready_next = 1'b0;
                    bvalid_next = 1'b1;
                    bresp_next = is_async_in_addr ? RESP_OKAY : RESP_SLVERR;
                end
            end
            
            WRITE_RESP: begin
                if (s_axi_bready && s_axi_bvalid) begin
                    write_next_state = WRITE_IDLE;
                    bvalid_next = 1'b0;
                    awready_next = 1'b1;
                end
            end
            
            default: begin
                write_next_state = WRITE_IDLE;
                awready_next = 1'b1;
                wready_next = 1'b0;
                bvalid_next = 1'b0;
            end
        endcase
    end
    
    // 写状态机 - 时序逻辑部分
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) begin
            write_state    <= WRITE_IDLE;
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= RESP_OKAY;
            async_in_reg   <= 16'h0000;
        end else begin
            write_state   <= write_next_state;
            s_axi_awready <= awready_next;
            s_axi_wready  <= wready_next;
            s_axi_bvalid  <= bvalid_next;
            s_axi_bresp   <= bresp_next;
            
            // 数据写入逻辑 - 只在特定条件下执行
            if (write_state == WRITE_DATA && s_axi_wvalid && s_axi_wready && is_async_in_addr) begin
                // 分开处理低8位和高8位，减少逻辑依赖链
                if (s_axi_wstrb[0]) async_in_reg[7:0]  <= s_axi_wdata[7:0];
                if (s_axi_wstrb[1]) async_in_reg[15:8] <= s_axi_wdata[15:8];
            end
        end
    end
    
    // 读状态机 - 组合逻辑部分
    always @(*) begin
        // 默认保持当前状态
        read_next_state = read_state;
        arready_next = s_axi_arready;
        rvalid_next = s_axi_rvalid;
        rresp_next = s_axi_rresp;
        rdata_next = s_axi_rdata;
        
        case (read_state)
            READ_IDLE: begin
                arready_next = 1'b1;
                if (s_axi_arvalid && s_axi_arready) begin
                    read_next_state = READ_DATA;
                    arready_next = 1'b0;
                    rvalid_next = 1'b1;
                    
                    // 分开处理不同地址的情况，减少复杂条件判断
                    if (is_read_async_in_addr) begin
                        rdata_next = {16'h0000, async_in_reg};
                        rresp_next = RESP_OKAY;
                    end else if (is_read_synced_not_addr) begin
                        rdata_next = {16'h0000, synced_not_reg};
                        rresp_next = RESP_OKAY;
                    end else begin
                        rdata_next = 32'h00000000;
                        rresp_next = RESP_SLVERR;
                    end
                end
            end
            
            READ_DATA: begin
                if (s_axi_rready && s_axi_rvalid) begin
                    read_next_state = READ_IDLE;
                    rvalid_next = 1'b0;
                    arready_next = 1'b1;
                end
            end
            
            default: begin
                read_next_state = READ_IDLE;
                arready_next = 1'b1;
                rvalid_next = 1'b0;
            end
        endcase
    end
    
    // 读状态机 - 时序逻辑部分
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) begin
            read_state     <= READ_IDLE;
            s_axi_arready  <= 1'b0;
            s_axi_rvalid   <= 1'b0;
            s_axi_rresp    <= RESP_OKAY;
            s_axi_rdata    <= 32'h00000000;
        end else begin
            read_state    <= read_next_state;
            s_axi_arready <= arready_next;
            s_axi_rvalid  <= rvalid_next;
            s_axi_rresp   <= rresp_next;
            s_axi_rdata   <= rdata_next;
        end
    end
    
    // 将取反操作拆分为两部分，缩短逻辑链
    reg [7:0] synced_not_low;
    reg [7:0] synced_not_high;
    
    // 核心功能：同步取反操作 - 拆分为低8位和高8位，减少关键路径
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) begin
            synced_not_low  <= 8'h00;
            synced_not_high <= 8'h00;
        end else begin
            synced_not_low  <= ~async_in_reg[7:0];    // 低8位取反
            synced_not_high <= ~async_in_reg[15:8];   // 高8位取反
        end
    end
    
    // 合并最终结果
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) begin
            synced_not_reg <= 16'h0000;
        end else begin
            synced_not_reg <= {synced_not_high, synced_not_low};
        end
    end

endmodule