//SystemVerilog
module cascaded_reset_dist(
    // AXI4-Lite interface signals
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    // AXI4-Lite write address channel
    input  wire [31:0] s_axi_awaddr,
    input  wire [2:0]  s_axi_awprot,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    // AXI4-Lite write data channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    // AXI4-Lite write response channel
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    // AXI4-Lite read address channel
    input  wire [31:0] s_axi_araddr,
    input  wire [2:0]  s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    // AXI4-Lite read data channel
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // Original output
    output wire [3:0]  rst_cascade
);

    // Internal signals
    reg [3:0] rst_cascade_reg;
    reg       rst_in_reg;
    
    // Pipeline stage registers
    reg [0:0] rst_stage1;
    reg [0:0] rst_stage2;
    reg [0:0] rst_stage3;
    reg [0:0] rst_stage4;
    
    // Pipeline valid signals
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // AXI4-Lite registers
    reg [31:0] reg_data_out;
    reg        reg_rvalid;
    reg        reg_bvalid;
    reg        aw_en;
    
    // Control register addresses
    localparam ADDR_RST_CONTROL = 4'h0;
    localparam ADDR_RST_STATUS  = 4'h4;
    
    // AXI4-Lite response codes
    localparam RESP_OKAY   = 2'b00;
    localparam RESP_SLVERR = 2'b10;
    
    // Write address channel handshake
    assign s_axi_awready = ~reg_bvalid & aw_en;
    
    // Write data channel handshake
    assign s_axi_wready = ~reg_bvalid & aw_en;
    
    // Write response channel signals
    assign s_axi_bresp = RESP_OKAY;
    assign s_axi_bvalid = reg_bvalid;
    
    // Read address channel handshake
    assign s_axi_arready = ~reg_rvalid;
    
    // Read data channel signals
    assign s_axi_rdata = reg_data_out;
    assign s_axi_rresp = RESP_OKAY;
    assign s_axi_rvalid = reg_rvalid;
    
    // Write address ready generation
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            aw_en <= 1'b1;
        end
        else begin
            if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                aw_en <= 1'b0;
            end
            else if (s_axi_bready && s_axi_bvalid) begin
                aw_en <= 1'b1;
            end
        end
    end
    
    // Write process
    reg [31:0] axi_awaddr;
    
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_awaddr <= 32'b0;
        end
        else begin
            if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                axi_awaddr <= s_axi_awaddr;
            end
        end
    end
    
    // Write data handling
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            reg_bvalid <= 1'b0;
            rst_in_reg <= 1'b1; // Reset is active on startup
        end
        else begin
            if (~s_axi_awready && s_axi_awvalid && ~s_axi_bvalid && s_axi_wvalid && aw_en) begin
                reg_bvalid <= 1'b1;
                
                if (axi_awaddr[3:0] == ADDR_RST_CONTROL && s_axi_wstrb[0]) begin
                    rst_in_reg <= s_axi_wdata[0];
                end
            end
            else if (s_axi_bready && s_axi_bvalid) begin
                reg_bvalid <= 1'b0;
            end
        end
    end
    
    // Read address handling
    reg [31:0] axi_araddr;
    
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_araddr <= 32'b0;
            reg_rvalid <= 1'b0;
        end
        else begin
            if (~s_axi_arready && s_axi_arvalid && ~reg_rvalid) begin
                axi_araddr <= s_axi_araddr;
                reg_rvalid <= 1'b1;
            end
            else if (reg_rvalid && s_axi_rready) begin
                reg_rvalid <= 1'b0;
            end
        end
    end
    
    // Read data handling
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            reg_data_out <= 32'b0;
        end
        else if (reg_rvalid && ~s_axi_rready) begin
            // Hold data until ready
        end
        else if (~s_axi_arready && s_axi_arvalid && ~reg_rvalid) begin
            case (axi_araddr[3:0])
                ADDR_RST_CONTROL: reg_data_out <= {31'b0, rst_in_reg};
                ADDR_RST_STATUS: reg_data_out <= {28'b0, rst_cascade_reg};
                default: reg_data_out <= 32'b0;
            endcase
        end
    end
    
    // Original cascaded reset logic with modified clock and reset source
    
    // Pipeline stage 1
    always @(posedge s_axi_aclk) begin
        if (rst_in_reg) begin
            rst_stage1 <= 1'b1;
            valid_stage1 <= 1'b1;
        end
        else begin
            rst_stage1 <= 1'b0;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2
    always @(posedge s_axi_aclk) begin
        if (rst_in_reg) begin
            rst_stage2 <= 1'b1;
            valid_stage2 <= 1'b1;
        end
        else begin
            rst_stage2 <= rst_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3
    always @(posedge s_axi_aclk) begin
        if (rst_in_reg) begin
            rst_stage3 <= 1'b1;
            valid_stage3 <= 1'b1;
        end
        else begin
            rst_stage3 <= rst_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Pipeline stage 4
    always @(posedge s_axi_aclk) begin
        if (rst_in_reg) begin
            rst_stage4 <= 1'b1;
            valid_stage4 <= 1'b1;
        end
        else begin
            rst_stage4 <= rst_stage3;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // Update internal register and output
    always @(posedge s_axi_aclk) begin
        rst_cascade_reg <= {rst_stage1, rst_stage2, rst_stage3, rst_stage4};
    end
    
    // Output assignment
    assign rst_cascade = rst_cascade_reg;

endmodule