//SystemVerilog
module hdr_to_sdr_codec (
    // Global signals
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite slave interface - Write address channel
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // AXI4-Lite slave interface - Write data channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // AXI4-Lite slave interface - Write response channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // AXI4-Lite slave interface - Read address channel
    input wire [31:0] s_axil_araddr,
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // AXI4-Lite slave interface - Read data channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);

    // Internal registers for HDR to SDR conversion
    reg [15:0] hdr_pixel_reg;
    reg [1:0] method_sel_reg;
    reg [7:0] custom_param_reg;
    reg [7:0] sdr_pixel_reg;
    
    // Register address map (byte offsets)
    localparam ADDR_HDR_PIXEL    = 5'h00;     // 0x00-0x03
    localparam ADDR_METHOD_SEL   = 5'h04;     // 0x04-0x07
    localparam ADDR_CUSTOM_PARAM = 5'h08;     // 0x08-0x0B
    localparam ADDR_SDR_PIXEL    = 5'h0C;     // 0x0C-0x0F
    
    // HDR to SDR conversion logic
    wire [7:0] log_result;
    
    // Instantiate log approximation module
    log_approximation log_approx_inst (
        .hdr_pixel(hdr_pixel_reg),
        .log_result(log_result)
    );
    
    // Instantiate conversion method selector module
    conversion_method_selector conv_method_inst (
        .hdr_pixel(hdr_pixel_reg),
        .method_sel(method_sel_reg),
        .log_result(log_result),
        .custom_param(custom_param_reg),
        .sdr_pixel(sdr_pixel_reg)
    );
    
    // Instantiate AXI4-Lite write interface handler
    axil_write_interface write_if_inst (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axil_awaddr(s_axil_awaddr[4:0]),
        .s_axil_awvalid(s_axil_awvalid),
        .s_axil_awready(s_axil_awready),
        .s_axil_wdata(s_axil_wdata),
        .s_axil_wstrb(s_axil_wstrb),
        .s_axil_wvalid(s_axil_wvalid),
        .s_axil_wready(s_axil_wready),
        .s_axil_bresp(s_axil_bresp),
        .s_axil_bvalid(s_axil_bvalid),
        .s_axil_bready(s_axil_bready),
        .hdr_pixel_reg(hdr_pixel_reg),
        .method_sel_reg(method_sel_reg),
        .custom_param_reg(custom_param_reg),
        .ADDR_HDR_PIXEL(ADDR_HDR_PIXEL),
        .ADDR_METHOD_SEL(ADDR_METHOD_SEL),
        .ADDR_CUSTOM_PARAM(ADDR_CUSTOM_PARAM)
    );

    // Instantiate AXI4-Lite read interface handler
    axil_read_interface read_if_inst (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axil_araddr(s_axil_araddr[4:0]),
        .s_axil_arvalid(s_axil_arvalid),
        .s_axil_arready(s_axil_arready),
        .s_axil_rdata(s_axil_rdata),
        .s_axil_rresp(s_axil_rresp),
        .s_axil_rvalid(s_axil_rvalid),
        .s_axil_rready(s_axil_rready),
        .hdr_pixel_reg(hdr_pixel_reg),
        .method_sel_reg(method_sel_reg),
        .custom_param_reg(custom_param_reg),
        .sdr_pixel_reg(sdr_pixel_reg),
        .ADDR_HDR_PIXEL(ADDR_HDR_PIXEL),
        .ADDR_METHOD_SEL(ADDR_METHOD_SEL),
        .ADDR_CUSTOM_PARAM(ADDR_CUSTOM_PARAM),
        .ADDR_SDR_PIXEL(ADDR_SDR_PIXEL)
    );

endmodule

// Log approximation module
module log_approximation (
    input wire [15:0] hdr_pixel,
    output reg [7:0] log_result
);
    reg [3:0] bit_pos;
    reg found;
    
    // Improved log2 approximation calculation
    always @(*) begin
        log_result = 0;
        bit_pos = 0;
        found = 0;
        
        // Priority encoder approach (optimized implementation)
        casez (hdr_pixel)
            16'b1???????????????: begin bit_pos = 4'd15; found = 1; end
            16'b01??????????????: begin bit_pos = 4'd14; found = 1; end
            16'b001?????????????: begin bit_pos = 4'd13; found = 1; end
            16'b0001????????????: begin bit_pos = 4'd12; found = 1; end
            16'b00001???????????: begin bit_pos = 4'd11; found = 1; end
            16'b000001??????????: begin bit_pos = 4'd10; found = 1; end
            16'b0000001?????????: begin bit_pos = 4'd9; found = 1; end
            16'b00000001????????: begin bit_pos = 4'd8; found = 1; end
            16'b000000001???????: begin bit_pos = 4'd7; found = 1; end
            16'b0000000001??????: begin bit_pos = 4'd6; found = 1; end
            16'b00000000001?????: begin bit_pos = 4'd5; found = 1; end
            16'b000000000001????: begin bit_pos = 4'd4; found = 1; end
            16'b0000000000001???: begin bit_pos = 4'd3; found = 1; end
            16'b00000000000001??: begin bit_pos = 4'd2; found = 1; end
            16'b000000000000001?: begin bit_pos = 4'd1; found = 1; end
            16'b0000000000000001: begin bit_pos = 4'd0; found = 1; end
            default: bit_pos = 4'd0;
        endcase
        
        log_result = {bit_pos, 4'b0};
    end
endmodule

// Conversion method selector module
module conversion_method_selector (
    input wire [15:0] hdr_pixel,
    input wire [1:0] method_sel,
    input wire [7:0] log_result,
    input wire [7:0] custom_param,
    output reg [7:0] sdr_pixel
);
    // Core conversion logic
    always @(*) begin
        case (method_sel)
            2'b00: sdr_pixel = hdr_pixel >> 8;  // Simple linear truncation
            2'b01: sdr_pixel = log_result;      // Log approximation
            2'b10: sdr_pixel = (hdr_pixel > 16'h00FF) ? 8'hFF : hdr_pixel[7:0]; // Clipping
            2'b11: sdr_pixel = ((hdr_pixel * custom_param) >> 8); // Custom scaling
            default: sdr_pixel = hdr_pixel[7:0];
        endcase
    end
endmodule

// AXI4-Lite write interface handler
module axil_write_interface (
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite write channels
    input wire [4:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Register outputs
    output reg [15:0] hdr_pixel_reg,
    output reg [1:0] method_sel_reg,
    output reg [7:0] custom_param_reg,
    
    // Address constants
    input wire [4:0] ADDR_HDR_PIXEL,
    input wire [4:0] ADDR_METHOD_SEL,
    input wire [4:0] ADDR_CUSTOM_PARAM
);
    // AXI4-Lite write FSM states
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_DATA = 2'b01;
    localparam WRITE_RESP = 2'b10;
    
    // FSM state register
    reg [1:0] write_state;
    
    // Stored write address
    reg [4:0] write_addr;
    
    // Write channel FSM
    always @(posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            write_state <= WRITE_IDLE;
            write_addr <= 0;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            
            // Initialize registers with defaults
            hdr_pixel_reg <= 16'h0000;
            method_sel_reg <= 2'b00;
            custom_param_reg <= 8'h80;  // Default scale factor of 128 (1.0)
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    // Ready to accept address
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b0;
                    
                    if (s_axil_awready && s_axil_awvalid) begin
                        write_addr <= s_axil_awaddr; // Store address
                        s_axil_awready <= 1'b0;
                        s_axil_wready <= 1'b1;
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    // Ready to accept data
                    s_axil_wready <= 1'b1;
                    
                    if (s_axil_wready && s_axil_wvalid) begin
                        s_axil_wready <= 1'b0;
                        s_axil_bvalid <= 1'b1;
                        s_axil_bresp <= 2'b00; // OKAY response
                        
                        // Register write logic
                        case (write_addr)
                            ADDR_HDR_PIXEL: begin
                                if (s_axil_wstrb[0]) hdr_pixel_reg[7:0] <= s_axil_wdata[7:0];
                                if (s_axil_wstrb[1]) hdr_pixel_reg[15:8] <= s_axil_wdata[15:8];
                            end
                            ADDR_METHOD_SEL: begin
                                if (s_axil_wstrb[0]) method_sel_reg <= s_axil_wdata[1:0];
                            end
                            ADDR_CUSTOM_PARAM: begin
                                if (s_axil_wstrb[0]) custom_param_reg <= s_axil_wdata[7:0];
                            end
                            // SDR_PIXEL is read-only
                            default: s_axil_bresp <= 2'b10; // SLVERR for invalid address
                        endcase
                        
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    // Wait for response channel handshake
                    if (s_axil_bvalid && s_axil_bready) begin
                        s_axil_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
endmodule

// AXI4-Lite read interface handler
module axil_read_interface (
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite read channels
    input wire [4:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // Register inputs
    input wire [15:0] hdr_pixel_reg,
    input wire [1:0] method_sel_reg,
    input wire [7:0] custom_param_reg,
    input wire [7:0] sdr_pixel_reg,
    
    // Address constants
    input wire [4:0] ADDR_HDR_PIXEL,
    input wire [4:0] ADDR_METHOD_SEL,
    input wire [4:0] ADDR_CUSTOM_PARAM,
    input wire [4:0] ADDR_SDR_PIXEL
);
    // AXI4-Lite read FSM states
    localparam READ_IDLE = 2'b00;
    localparam READ_DATA = 2'b01;
    
    // FSM state register
    reg [1:0] read_state;
    
    // Read channel FSM
    always @(posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            read_state <= READ_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= 2'b00;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    // Ready to accept address
                    s_axil_arready <= 1'b1;
                    
                    if (s_axil_arready && s_axil_arvalid) begin
                        s_axil_arready <= 1'b0;
                        s_axil_rvalid <= 1'b1;
                        
                        // Register read logic
                        case (s_axil_araddr)
                            ADDR_HDR_PIXEL:    s_axil_rdata <= {16'h0000, hdr_pixel_reg};
                            ADDR_METHOD_SEL:   s_axil_rdata <= {30'h0, method_sel_reg};
                            ADDR_CUSTOM_PARAM: s_axil_rdata <= {24'h0, custom_param_reg};
                            ADDR_SDR_PIXEL:    s_axil_rdata <= {24'h0, sdr_pixel_reg};
                            default: begin
                                s_axil_rdata <= 32'h0;
                                s_axil_rresp <= 2'b10; // SLVERR for invalid address
                            end
                        endcase
                        
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    // Wait for read data channel handshake
                    if (s_axil_rvalid && s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                        s_axil_rresp <= 2'b00;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end
endmodule