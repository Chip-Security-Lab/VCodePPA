//SystemVerilog
module sync_rom_axi4lite (
    // Global signals
    input wire        s_axi_aclk,
    input wire        s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input wire [31:0] s_axi_awaddr,
    input wire        s_axi_awvalid,
    output reg        s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0]  s_axi_wstrb,
    input wire        s_axi_wvalid,
    output reg        s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output reg [1:0]  s_axi_bresp,
    output reg        s_axi_bvalid,
    input wire        s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] s_axi_araddr,
    input wire        s_axi_arvalid,
    output reg        s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0]  s_axi_rresp,
    output reg        s_axi_rvalid,
    input wire        s_axi_rready
);

    // Memory array definition - expanded to 32-bit data width
    reg [7:0] rom [0:15];
    reg [3:0] read_addr;
    reg       read_in_progress;

    // Initialize ROM with values (unchanged)
    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34; rom[2] = 8'h56; rom[3] = 8'h78;
        rom[4] = 8'h9A; rom[5] = 8'hBC; rom[6] = 8'hDE; rom[7] = 8'hF0;
        rom[8] = 8'h00; rom[9] = 8'h00; rom[10] = 8'h00; rom[11] = 8'h00;
        rom[12] = 8'h00; rom[13] = 8'h00; rom[14] = 8'h00; rom[15] = 8'h00;
    end

    // Write Address Channel - ROM is read-only, so we just acknowledge
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
        end else begin
            // Always ready to accept write address (but we'll ignore it)
            s_axi_awready <= s_axi_awvalid && !s_axi_awready;
        end
    end

    // Write Data Channel - ROM is read-only, so we just acknowledge
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
        end else begin
            // Always ready to accept write data (but we'll ignore it)
            s_axi_wready <= s_axi_wvalid && !s_axi_wready;
        end
    end

    // Write Response Channel - Always return error for write attempts
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
        end else begin
            if (s_axi_awready && s_axi_wready && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b10; // SLVERR - ROM is read-only
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // Read Address Channel
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            read_in_progress <= 1'b0;
            read_addr <= 4'b0;
        end else begin
            if (s_axi_arvalid && !s_axi_arready && !read_in_progress) begin
                // Accept the read address and capture it
                s_axi_arready <= 1'b1;
                read_addr <= s_axi_araddr[5:2]; // Use only relevant bits
                read_in_progress <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
                
                if (s_axi_rvalid && s_axi_rready) begin
                    read_in_progress <= 1'b0;
                end
            end
        end
    end

    // Read Data Channel
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            s_axi_rdata <= 32'b0;
        end else begin
            if (read_in_progress && !s_axi_rvalid) begin
                // Read from memory and provide data
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00; // OKAY
                
                // Zero-extend the 8-bit data to 32-bit
                s_axi_rdata <= {24'b0, rom[read_addr]};
            end else if (s_axi_rvalid && s_axi_rready) begin
                // Clear valid flag when data is accepted
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule