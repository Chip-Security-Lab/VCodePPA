//SystemVerilog
// SystemVerilog IEEE 1364-2005
module activity_clock_gate (
    // Clock and Reset
    input  wire        s_axi_aclk,      // AXI4-Lite Clock
    input  wire        s_axi_aresetn,   // AXI4-Lite Reset (Active Low)
    
    // AXI4-Lite Write Address Channel
    input  wire [31:0] s_axi_awaddr,    // Write Address
    input  wire [2:0]  s_axi_awprot,    // Write Protection Type
    input  wire        s_axi_awvalid,   // Write Address Valid
    output wire        s_axi_awready,   // Write Address Ready
    
    // AXI4-Lite Write Data Channel
    input  wire [31:0] s_axi_wdata,     // Write Data
    input  wire [3:0]  s_axi_wstrb,     // Write Strobes
    input  wire        s_axi_wvalid,    // Write Valid
    output wire        s_axi_wready,    // Write Ready
    
    // AXI4-Lite Write Response Channel
    output wire [1:0]  s_axi_bresp,     // Write Response
    output wire        s_axi_bvalid,    // Write Response Valid
    input  wire        s_axi_bready,    // Write Response Ready
    
    // AXI4-Lite Read Address Channel
    input  wire [31:0] s_axi_araddr,    // Read Address
    input  wire [2:0]  s_axi_arprot,    // Read Protection Type
    input  wire        s_axi_arvalid,   // Read Address Valid
    output wire        s_axi_arready,   // Read Address Ready
    
    // AXI4-Lite Read Data Channel
    output wire [31:0] s_axi_rdata,     // Read Data
    output wire [1:0]  s_axi_rresp,     // Read Response
    output wire        s_axi_rvalid,    // Read Valid
    input  wire        s_axi_rready,    // Read Ready
    
    // Original clock output
    output wire        clk_out          // Clock gate output
);

    // Internal registers for AXI4-Lite interface
    reg        awready_r;
    reg        wready_r;
    reg        bvalid_r;
    reg        arready_r;
    reg        rvalid_r;
    reg [31:0] rdata_r;
    
    // Register map (byte addresses)
    localparam REG_DATA_IN     = 4'h0;  // Offset 0x00
    localparam REG_PREV_DATA   = 4'h4;  // Offset 0x04
    localparam REG_STATUS      = 4'h8;  // Offset 0x08
    
    // Internal registers to store the core functionality data
    reg [7:0]  data_in_reg;        // Current data input
    reg [7:0]  prev_data_reg;      // Previous cycle data
    reg        activity_detected_sync; // Synchronized activity detection signal
    wire       data_changed;       // Data change detection signal
    
    // Write address channel handshake
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            awready_r <= 1'b0;
        end else if (s_axi_awvalid && !awready_r) begin
            awready_r <= 1'b1;
        end else begin
            awready_r <= 1'b0;
        end
    end
    
    // Write data channel handshake
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            wready_r <= 1'b0;
        end else if (s_axi_wvalid && !wready_r) begin
            wready_r <= 1'b1;
        end else begin
            wready_r <= 1'b0;
        end
    end
    
    // Write response channel handshake
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            bvalid_r <= 1'b0;
        end else if (awready_r && wready_r && !bvalid_r) begin
            bvalid_r <= 1'b1;
        end else if (bvalid_r && s_axi_bready) begin
            bvalid_r <= 1'b0;
        end
    end
    
    // Write operation - update registers based on write address
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            data_in_reg <= 8'h00;
            prev_data_reg <= 8'h00;
        end else if (s_axi_awvalid && s_axi_wvalid && awready_r && wready_r) begin
            case (s_axi_awaddr[3:0])
                REG_DATA_IN: begin
                    if (s_axi_wstrb[0]) data_in_reg <= s_axi_wdata[7:0];
                end
                REG_PREV_DATA: begin
                    if (s_axi_wstrb[0]) prev_data_reg <= s_axi_wdata[7:0];
                end
                default: begin
                    // No action for unrecognized addresses
                end
            endcase
        end
    end
    
    // Read address channel handshake
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            arready_r <= 1'b0;
        end else if (s_axi_arvalid && !arready_r) begin
            arready_r <= 1'b1;
        end else begin
            arready_r <= 1'b0;
        end
    end
    
    // Read data channel logic
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            rvalid_r <= 1'b0;
            rdata_r <= 32'h0;
        end else if (s_axi_arvalid && arready_r && !rvalid_r) begin
            rvalid_r <= 1'b1;
            case (s_axi_araddr[3:0])
                REG_DATA_IN: begin
                    rdata_r <= {24'h0, data_in_reg};
                end
                REG_PREV_DATA: begin
                    rdata_r <= {24'h0, prev_data_reg};
                end
                REG_STATUS: begin
                    rdata_r <= {31'h0, activity_detected_sync};
                end
                default: begin
                    rdata_r <= 32'h0;
                end
            endcase
        end else if (rvalid_r && s_axi_rready) begin
            rvalid_r <= 1'b0;
        end
    end
    
    // Core functionality logic (preserved from original design)
    // Data change detection
    assign data_changed = (data_in_reg != prev_data_reg);
    
    // Activity detection synchronization
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            activity_detected_sync <= 1'b0;
        end else begin
            activity_detected_sync <= data_changed;
        end
    end
    
    // Clock gating output generation
    assign clk_out = s_axi_aclk & activity_detected_sync;
    
    // Connect internal registers to AXI4-Lite interface outputs
    assign s_axi_awready = awready_r;
    assign s_axi_wready = wready_r;
    assign s_axi_bresp = 2'b00;  // OKAY response
    assign s_axi_bvalid = bvalid_r;
    assign s_axi_arready = arready_r;
    assign s_axi_rdata = rdata_r;
    assign s_axi_rresp = 2'b00;  // OKAY response
    assign s_axi_rvalid = rvalid_r;

endmodule