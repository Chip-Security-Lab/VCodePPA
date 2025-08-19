//SystemVerilog
module rgb_to_gray_codec (
    // Clock and reset
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite slave interface
    // Write address channel
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write data channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write response channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read address channel
    input wire [31:0] s_axil_araddr,
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read data channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);

    // Register addresses (byte-addressable)
    localparam REG_RGB_DATA = 4'h0;    // RGB input register (address 0x00)
    localparam REG_GRAY_OUT = 4'h4;    // Grayscale output register (address 0x04)
    
    // Internal registers
    reg [23:0] rgb_pixel;
    wire [7:0] gray_out;
    
    // Grayscale conversion logic
    // Standard luminance calculation: Y = 0.299R + 0.587G + 0.114B
    wire [15:0] r_contrib = 77 * rgb_pixel[23:16];  // 0.299 * 256 ~= 77
    wire [15:0] g_contrib = 150 * rgb_pixel[15:8];  // 0.587 * 256 ~= 150
    wire [15:0] b_contrib = 29 * rgb_pixel[7:0];    // 0.114 * 256 ~= 29
    
    assign gray_out = (r_contrib + g_contrib + b_contrib) >> 8;
    
    // FSM states for AXI4-Lite interface
    localparam IDLE = 2'b00;
    localparam WRITE = 2'b01;
    localparam READ = 2'b10;
    
    reg [1:0] axi_state;
    reg [3:0] addr_reg;
    
    // Reset and state transition logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            axi_state <= IDLE;
        end else begin
            case (axi_state)
                IDLE: begin
                    // Prioritize write transaction over read
                    if (s_axil_awvalid && s_axil_wvalid) begin
                        axi_state <= WRITE;
                    end else if (s_axil_arvalid) begin
                        axi_state <= READ;
                    end
                end
                
                WRITE: begin
                    axi_state <= IDLE;
                end
                
                READ: begin
                    axi_state <= IDLE;
                end
                
                default: axi_state <= IDLE;
            endcase
        end
    end
    
    // Address register handling
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            addr_reg <= 4'h0;
        end else begin
            if (axi_state == IDLE) begin
                if (s_axil_awvalid && s_axil_wvalid) begin
                    addr_reg <= s_axil_awaddr[5:2];
                end else if (s_axil_arvalid) begin
                    addr_reg <= s_axil_araddr[5:2];
                end
            end
        end
    end
    
    // Write address channel control
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready <= 1'b0;
        end else begin
            if (axi_state == IDLE && s_axil_awvalid && s_axil_wvalid) begin
                s_axil_awready <= 1'b1;
            end else begin
                s_axil_awready <= 1'b0;
            end
        end
    end
    
    // Write data channel control
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_wready <= 1'b0;
        end else begin
            if (axi_state == IDLE && s_axil_awvalid && s_axil_wvalid) begin
                s_axil_wready <= 1'b1;
            end else begin
                s_axil_wready <= 1'b0;
            end
        end
    end
    
    // Write data to registers
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rgb_pixel <= 24'h0;
        end else begin
            if (axi_state == WRITE) begin
                if (addr_reg == REG_RGB_DATA[3:0]) begin
                    if (s_axil_wstrb[0]) rgb_pixel[7:0] <= s_axil_wdata[7:0];
                    if (s_axil_wstrb[1]) rgb_pixel[15:8] <= s_axil_wdata[15:8];
                    if (s_axil_wstrb[2]) rgb_pixel[23:16] <= s_axil_wdata[23:16];
                end
            end
        end
    end
    
    // Write response channel control
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
        end else begin
            if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end else if (axi_state == WRITE) begin
                s_axil_bvalid <= 1'b1;
                if (addr_reg == REG_RGB_DATA[3:0]) begin
                    s_axil_bresp <= 2'b00; // OKAY response
                end else begin
                    s_axil_bresp <= 2'b10; // SLVERR for invalid address
                end
            end
        end
    end
    
    // Read address channel control
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_arready <= 1'b0;
        end else begin
            if (axi_state == IDLE && s_axil_arvalid && !(s_axil_awvalid && s_axil_wvalid)) begin
                s_axil_arready <= 1'b1;
            end else begin
                s_axil_arready <= 1'b0;
            end
        end
    end
    
    // Read data channel control
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= 2'b00;
        end else begin
            if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end else if (axi_state == READ) begin
                s_axil_rvalid <= 1'b1;
                
                if (addr_reg == REG_RGB_DATA[3:0]) begin
                    s_axil_rdata <= {8'h0, rgb_pixel};
                    s_axil_rresp <= 2'b00; // OKAY response
                end else if (addr_reg == REG_GRAY_OUT[3:0]) begin
                    s_axil_rdata <= {24'h0, gray_out};
                    s_axil_rresp <= 2'b00; // OKAY response
                end else begin
                    s_axil_rdata <= 32'h0;
                    s_axil_rresp <= 2'b10; // SLVERR for invalid address
                end
            end
        end
    end

endmodule