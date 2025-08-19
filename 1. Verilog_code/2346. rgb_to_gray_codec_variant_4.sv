//SystemVerilog
module rgb_to_gray_codec (
    // Clock and reset
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite write address channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    
    // AXI4-Lite write data channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    
    // AXI4-Lite write response channel
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite read address channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    
    // AXI4-Lite read data channel
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    // Internal registers
    reg [23:0] rgb_pixel_reg;
    reg [7:0]  gray_out_reg;
    
    // Register address map (byte addressing)
    localparam REG_RGB_PIXEL = 4'h0;  // Offset 0x00
    localparam REG_GRAY_OUT  = 4'h4;  // Offset 0x04
    
    // AXI response codes
    localparam RESP_OKAY   = 2'b00;
    localparam RESP_SLVERR = 2'b10;
    
    // Register for address capture
    reg [3:0] read_addr_reg;
    reg [3:0] write_addr_reg;
    
    // RGB to grayscale conversion - optimized implementation
    // Pre-compute coefficients to reduce multiplication count
    localparam [7:0] R_COEFF = 8'd77;   // 0.299 * 256 ~= 77
    localparam [7:0] G_COEFF = 8'd150;  // 0.587 * 256 ~= 150
    localparam [7:0] B_COEFF = 8'd29;   // 0.114 * 256 ~= 29
    
    // Use DSP-friendly fixed point arithmetic
    wire [7:0] r_val = rgb_pixel_reg[23:16];
    wire [7:0] g_val = rgb_pixel_reg[15:8];
    wire [7:0] b_val = rgb_pixel_reg[7:0];
    
    // Parallel multiply structure for better timing and area
    wire [15:0] r_contrib = R_COEFF * r_val;
    wire [15:0] g_contrib = G_COEFF * g_val;
    wire [15:0] b_contrib = B_COEFF * b_val;
    
    // Sum component contributions and shift
    wire [16:0] gray_sum = r_contrib + g_contrib + b_contrib;
    wire [7:0] gray_result = gray_sum[15:8]; // Shift by 8 bits (divide by 256)
    
    // Write address channel logic - optimized handshaking
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b1; // Start ready to accept transactions
            write_addr_reg <= 4'h0;
        end else begin
            if (s_axi_awvalid && s_axi_awready) begin
                // Address captured, deassert ready until data processed
                s_axi_awready <= 1'b0;
                write_addr_reg <= s_axi_awaddr[5:2];
            end else if (s_axi_bvalid && s_axi_bready) begin
                // Transaction complete, ready for next address
                s_axi_awready <= 1'b1;
            end
        end
    end
    
    // Write data channel logic - streamlined for faster throughput
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b1; // Start ready to accept data
            rgb_pixel_reg <= 24'h0;
        end else begin
            if (s_axi_wvalid && s_axi_wready) begin
                s_axi_wready <= 1'b0; // Data accepted, deassert ready
                
                // Handle write to RGB register with byte enables
                if (write_addr_reg == REG_RGB_PIXEL[3:0]) begin
                    if (s_axi_wstrb[0]) rgb_pixel_reg[7:0]   <= s_axi_wdata[7:0];
                    if (s_axi_wstrb[1]) rgb_pixel_reg[15:8]  <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[2]) rgb_pixel_reg[23:16] <= s_axi_wdata[23:16];
                end
            end else if (s_axi_bvalid && s_axi_bready) begin
                // Transaction complete, ready for next data
                s_axi_wready <= 1'b1;
            end
        end
    end
    
    // Update gray output register - simplified logic path
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            gray_out_reg <= 8'h0;
        end else begin
            // Update only when RGB value has changed and write is complete
            if (s_axi_wvalid && s_axi_wready && write_addr_reg == REG_RGB_PIXEL[3:0]) begin
                gray_out_reg <= gray_result;
            end
        end
    end
    
    // Write response channel logic - optimized state transitions
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= RESP_OKAY;
        end else begin
            if (s_axi_wvalid && s_axi_wready) begin
                s_axi_bvalid <= 1'b1;
                // Efficiently check for valid address using comparison range
                s_axi_bresp <= (write_addr_reg <= REG_RGB_PIXEL[3:0]) ? RESP_OKAY : RESP_SLVERR;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end
    
    // Read address channel logic - improved acceptance speed
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b1; // Start ready to accept read requests
            read_addr_reg <= 4'h0;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_arready <= 1'b0; // Address captured, deassert ready
                read_addr_reg <= s_axi_araddr[5:2];
            end else if (s_axi_rvalid && s_axi_rready) begin
                // Read transaction complete, ready for next
                s_axi_arready <= 1'b1;
            end
        end
    end
    
    // Read data channel logic - optimized register comparison
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= RESP_OKAY;
            s_axi_rdata <= 32'h0;
        end else begin
            if (s_axi_arready && s_axi_arvalid) begin
                s_axi_rvalid <= 1'b1;
                
                // Efficient range-based addressing
                if (read_addr_reg == REG_RGB_PIXEL[3:0]) begin
                    s_axi_rdata <= {8'h0, rgb_pixel_reg};
                    s_axi_rresp <= RESP_OKAY;
                end else if (read_addr_reg == REG_GRAY_OUT[3:0]) begin
                    s_axi_rdata <= {24'h0, gray_out_reg};
                    s_axi_rresp <= RESP_OKAY;
                end else begin
                    s_axi_rdata <= 32'h0;
                    s_axi_rresp <= RESP_SLVERR;
                end
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule