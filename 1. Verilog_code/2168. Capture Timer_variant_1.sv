//SystemVerilog
module capture_timer (
    // Clock and Reset
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input  wire [31:0] s_axi_awaddr,
    input  wire [2:0]  s_axi_awprot,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input  wire [31:0] s_axi_araddr,
    input  wire [2:0]  s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // Original capture input
    input  wire        capture_i
);

    // Internal signals
    reg  [31:0] value_r;
    reg  [31:0] capture_r;
    reg         capture_valid_r;
    wire        en_w;
    
    // Register address map (byte addressing)
    localparam ADDR_VALUE         = 8'h00; // 0x00: Timer value register
    localparam ADDR_CAPTURE       = 8'h04; // 0x04: Capture value register
    localparam ADDR_CONTROL       = 8'h08; // 0x08: Control register (bit 0: enable)
    localparam ADDR_STATUS        = 8'h0C; // 0x0C: Status register (bit 0: capture valid)
    
    // AXI4-Lite interface registers
    reg         axi_awready_r;
    reg         axi_wready_r;
    reg         axi_bvalid_r;
    reg [1:0]   axi_bresp_r;
    reg         axi_arready_r;
    reg [31:0]  axi_rdata_r;
    reg         axi_rvalid_r;
    reg [1:0]   axi_rresp_r;
    
    // Address latches
    reg [31:0]  axi_awaddr_latch_r;
    reg [31:0]  axi_araddr_latch_r;
    
    // Control and status registers
    reg         ctrl_enable_r;
    
    // 增加流水线寄存器
    reg capture_d1, capture_d2, capture_d3, capture_d4;
    reg capture_event_stage1, capture_event_stage2;
    reg [31:0] value_stage1, value_stage2, value_stage3;
    
    // AXI4-Lite write channels handling
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_awready_r <= 1'b0;
            axi_wready_r <= 1'b0;
            axi_bvalid_r <= 1'b0;
            axi_bresp_r <= 2'b00;
            axi_awaddr_latch_r <= 32'h0;
            ctrl_enable_r <= 1'b0;
        end else begin
            // Write address handshake
            if (~axi_awready_r && s_axi_awvalid) begin
                axi_awready_r <= 1'b1;
                axi_awaddr_latch_r <= s_axi_awaddr;
            end else begin
                axi_awready_r <= 1'b0;
            end
            
            // Write data handshake
            if (~axi_wready_r && s_axi_wvalid) begin
                axi_wready_r <= 1'b1;
                
                // Handle register writes
                if (axi_awaddr_latch_r[7:0] == ADDR_CONTROL && s_axi_wstrb[0]) begin
                    ctrl_enable_r <= s_axi_wdata[0];
                end
            end else begin
                axi_wready_r <= 1'b0;
            end
            
            // Write response handshake
            if (~axi_bvalid_r && axi_wready_r && axi_awready_r) begin
                axi_bvalid_r <= 1'b1;
                axi_bresp_r <= 2'b00; // OKAY response
            end else if (axi_bvalid_r && s_axi_bready) begin
                axi_bvalid_r <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite read channels handling
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_arready_r <= 1'b0;
            axi_rvalid_r <= 1'b0;
            axi_rdata_r <= 32'h0;
            axi_rresp_r <= 2'b00;
            axi_araddr_latch_r <= 32'h0;
        end else begin
            // Read address handshake
            if (~axi_arready_r && s_axi_arvalid) begin
                axi_arready_r <= 1'b1;
                axi_araddr_latch_r <= s_axi_araddr;
            end else begin
                axi_arready_r <= 1'b0;
            end
            
            // Read data handshake
            if (~axi_rvalid_r && axi_arready_r) begin
                axi_rvalid_r <= 1'b1;
                axi_rresp_r <= 2'b00; // OKAY response
                
                // Read from appropriate register
                case (axi_araddr_latch_r[7:0])
                    ADDR_VALUE:    axi_rdata_r <= value_r;
                    ADDR_CAPTURE:  axi_rdata_r <= capture_r;
                    ADDR_CONTROL:  axi_rdata_r <= {31'h0, ctrl_enable_r};
                    ADDR_STATUS:   axi_rdata_r <= {31'h0, capture_valid_r};
                    default:       axi_rdata_r <= 32'h0;
                endcase
            end else if (axi_rvalid_r && s_axi_rready) begin
                axi_rvalid_r <= 1'b0;
            end
        end
    end
    
    // Connect enable signal
    assign en_w = ctrl_enable_r;
    
    // 计数器逻辑 - 流水线级别1
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) 
            value_r <= 32'h0;
        else if (en_w) 
            value_r <= value_r + 32'h1;
    end
    
    // 捕获输入同步寄存器 - 增加深度
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin 
            capture_d1 <= 1'b0; 
            capture_d2 <= 1'b0;
            capture_d3 <= 1'b0;
            capture_d4 <= 1'b0;
        end
        else begin 
            capture_d1 <= capture_i; 
            capture_d2 <= capture_d1;
            capture_d3 <= capture_d2;
            capture_d4 <= capture_d3;
        end
    end
    
    // 边沿检测流水线 - 分成多级
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            capture_event_stage1 <= 1'b0;
            capture_event_stage2 <= 1'b0;
        end
        else begin
            // 第一级：边沿检测
            capture_event_stage1 <= capture_d2 & ~capture_d3;
            // 第二级：传递边沿检测结果
            capture_event_stage2 <= capture_event_stage1;
        end
    end
    
    // 数值流水线 - 将原始值同步传递
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            value_stage1 <= 32'h0;
            value_stage2 <= 32'h0;
            value_stage3 <= 32'h0;
        end
        else begin
            value_stage1 <= value_r;
            value_stage2 <= value_stage1;
            value_stage3 <= value_stage2;
        end
    end
    
    // 输出流水线级
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin 
            capture_r <= 32'h0; 
            capture_valid_r <= 1'b0; 
        end
        else begin
            capture_valid_r <= capture_event_stage2;
            if (capture_event_stage2) capture_r <= value_stage3;
        end
    end
    
    // Assign outputs
    assign s_axi_awready = axi_awready_r;
    assign s_axi_wready = axi_wready_r;
    assign s_axi_bresp = axi_bresp_r;
    assign s_axi_bvalid = axi_bvalid_r;
    assign s_axi_arready = axi_arready_r;
    assign s_axi_rdata = axi_rdata_r;
    assign s_axi_rresp = axi_rresp_r;
    assign s_axi_rvalid = axi_rvalid_r;
    
endmodule