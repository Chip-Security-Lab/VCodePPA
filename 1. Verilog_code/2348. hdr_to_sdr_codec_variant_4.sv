//SystemVerilog
module hdr_to_sdr_codec #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)(
    // AXI4-Lite interfaces
    // Global signals
    input  wire                     s_axi_aclk,
    input  wire                     s_axi_aresetn,
    
    // Write address channel
    input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire                     s_axi_awvalid,
    output reg                      s_axi_awready,
    
    // Write data channel
    input  wire [DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0]  s_axi_wstrb,
    input  wire                     s_axi_wvalid,
    output reg                      s_axi_wready,
    
    // Write response channel
    output reg  [1:0]               s_axi_bresp,
    output reg                      s_axi_bvalid,
    input  wire                     s_axi_bready,
    
    // Read address channel
    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire                     s_axi_arvalid,
    output reg                      s_axi_arready,
    
    // Read data channel
    output reg  [DATA_WIDTH-1:0]    s_axi_rdata,
    output reg  [1:0]               s_axi_rresp,
    output reg                      s_axi_rvalid,
    input  wire                     s_axi_rready,
    
    // Output pixel
    output wire [7:0]               sdr_pixel_out
);

    // Local registers
    reg [15:0] hdr_pixel_reg;
    reg [1:0]  method_sel_reg;
    reg [7:0]  custom_param_reg;
    reg [7:0]  sdr_pixel_reg;
    
    // Internal signals for codec logic
    reg [7:0] log_result;
    reg [3:0] bit_pos;
    reg       found;
    
    // AXI4-Lite write transaction states
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    // AXI4-Lite read transaction states
    localparam READ_IDLE  = 2'b00;
    localparam READ_ADDR  = 2'b01;
    localparam READ_DATA  = 2'b10;
    
    // Register addresses
    localparam ADDR_HDR_PIXEL   = 8'h00;
    localparam ADDR_METHOD_SEL  = 8'h04;
    localparam ADDR_CUSTOM_PARAM = 8'h08;
    localparam ADDR_SDR_PIXEL   = 8'h0C;
    
    // FSM state registers
    reg [1:0] write_state, write_next;
    reg [1:0] read_state, read_next;
    
    // Captured address for write and read operations
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [ADDR_WIDTH-1:0] araddr_reg;
    
    // Reset and state transitions
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            write_state <= WRITE_IDLE;
            read_state <= READ_IDLE;
            hdr_pixel_reg <= 16'h0000;
            method_sel_reg <= 2'b00;
            custom_param_reg <= 8'h00;
            awaddr_reg <= {ADDR_WIDTH{1'b0}};
            araddr_reg <= {ADDR_WIDTH{1'b0}};
        end else begin
            write_state <= write_next;
            read_state <= read_next;
        end
    end
    
    // Write transaction FSM
    always @(*) begin
        // Default assignments
        write_next = write_state;
        s_axi_awready = 1'b0;
        s_axi_wready = 1'b0;
        s_axi_bvalid = 1'b0;
        s_axi_bresp = 2'b00; // OKAY
        
        // State-specific logic
        if (write_state == WRITE_IDLE) begin
            if (s_axi_awvalid) begin
                write_next = WRITE_ADDR;
                s_axi_awready = 1'b1;
            end
        end
        else if (write_state == WRITE_ADDR) begin
            write_next = WRITE_DATA;
            s_axi_wready = 1'b1;
        end
        else if (write_state == WRITE_DATA) begin
            if (s_axi_wvalid) begin
                write_next = WRITE_RESP;
                s_axi_wready = 1'b0;
            end else begin
                s_axi_wready = 1'b1;
            end
        end
        else if (write_state == WRITE_RESP) begin
            s_axi_bvalid = 1'b1;
            if (s_axi_bready) begin
                write_next = WRITE_IDLE;
            end
        end
    end
    
    // Read transaction FSM
    always @(*) begin
        // Default assignments
        read_next = read_state;
        s_axi_arready = 1'b0;
        s_axi_rvalid = 1'b0;
        s_axi_rresp = 2'b00; // OKAY
        s_axi_rdata = {DATA_WIDTH{1'b0}};
        
        // State-specific logic
        if (read_state == READ_IDLE) begin
            if (s_axi_arvalid) begin
                read_next = READ_ADDR;
                s_axi_arready = 1'b1;
            end
        end
        else if (read_state == READ_ADDR) begin
            read_next = READ_DATA;
        end
        else if (read_state == READ_DATA) begin
            s_axi_rvalid = 1'b1;
            
            // Address-based data selection
            if (araddr_reg[7:0] == ADDR_HDR_PIXEL) begin
                s_axi_rdata = {16'h0000, hdr_pixel_reg};
            end
            else if (araddr_reg[7:0] == ADDR_METHOD_SEL) begin
                s_axi_rdata = {30'h0, method_sel_reg};
            end
            else if (araddr_reg[7:0] == ADDR_CUSTOM_PARAM) begin
                s_axi_rdata = {24'h0, custom_param_reg};
            end
            else if (araddr_reg[7:0] == ADDR_SDR_PIXEL) begin
                s_axi_rdata = {24'h0, sdr_pixel_reg};
            end
            else begin
                s_axi_rdata = 32'h0;
            end
            
            if (s_axi_rready) begin
                read_next = READ_IDLE;
            end
        end
    end
    
    // Register writes
    always @(posedge s_axi_aclk) begin
        if (write_state == WRITE_ADDR && s_axi_awvalid && s_axi_awready) begin
            awaddr_reg <= s_axi_awaddr;
        end
        
        if (write_state == WRITE_DATA && s_axi_wvalid && s_axi_wready) begin
            if (awaddr_reg[7:0] == ADDR_HDR_PIXEL) begin
                if (s_axi_wstrb[0]) hdr_pixel_reg[7:0] <= s_axi_wdata[7:0];
                if (s_axi_wstrb[1]) hdr_pixel_reg[15:8] <= s_axi_wdata[15:8];
            end
            else if (awaddr_reg[7:0] == ADDR_METHOD_SEL) begin
                if (s_axi_wstrb[0]) method_sel_reg <= s_axi_wdata[1:0];
            end
            else if (awaddr_reg[7:0] == ADDR_CUSTOM_PARAM) begin
                if (s_axi_wstrb[0]) custom_param_reg <= s_axi_wdata[7:0];
            end
        end
    end
    
    // Register reads
    always @(posedge s_axi_aclk) begin
        if (read_state == READ_ADDR && s_axi_arvalid && s_axi_arready) begin
            araddr_reg <= s_axi_araddr;
        end
    end
    
    // Improved log2 approximation calculation with simplified hierarchy
    always @(*) begin
        // Default values
        log_result = 0;
        bit_pos = 0;
        found = 0;
        
        // First check if any bit is set
        if (hdr_pixel_reg != 16'h0000) begin
            // Check upper byte first (bits 15-8)
            if (hdr_pixel_reg[15:8] != 8'h00) begin
                // Check bits 15-12
                if (hdr_pixel_reg[15:12] != 4'h0) begin
                    // Check bits 15-14
                    if (hdr_pixel_reg[15]) begin
                        bit_pos = 4'd15;
                    end else begin // hdr_pixel_reg[14] must be 1
                        bit_pos = 4'd14;
                    end
                end else begin // Bits 11-8 have the MSB
                    // Check bits 11-10
                    if (hdr_pixel_reg[11:10] != 2'b00) begin
                        if (hdr_pixel_reg[11]) begin
                            bit_pos = 4'd11;
                        end else begin // hdr_pixel_reg[10] must be 1
                            bit_pos = 4'd10;
                        end
                    end else begin // Bits 9-8 have the MSB
                        if (hdr_pixel_reg[9]) begin
                            bit_pos = 4'd9;
                        end else begin // hdr_pixel_reg[8] must be 1
                            bit_pos = 4'd8;
                        end
                    end
                end
            end else begin // Lower byte (bits 7-0) has the MSB
                // Check bits 7-4
                if (hdr_pixel_reg[7:4] != 4'h0) begin
                    // Check bits 7-6
                    if (hdr_pixel_reg[7:6] != 2'b00) begin
                        if (hdr_pixel_reg[7]) begin
                            bit_pos = 4'd7;
                        end else begin // hdr_pixel_reg[6] must be 1
                            bit_pos = 4'd6;
                        end
                    end else begin // Bits 5-4 have the MSB
                        if (hdr_pixel_reg[5]) begin
                            bit_pos = 4'd5;
                        end else begin // hdr_pixel_reg[4] must be 1
                            bit_pos = 4'd4;
                        end
                    end
                end else begin // Bits 3-0 have the MSB
                    // Check bits 3-2
                    if (hdr_pixel_reg[3:2] != 2'b00) begin
                        if (hdr_pixel_reg[3]) begin
                            bit_pos = 4'd3;
                        end else begin // hdr_pixel_reg[2] must be 1
                            bit_pos = 4'd2;
                        end
                    end else begin // Bits 1-0 have the MSB
                        if (hdr_pixel_reg[1]) begin
                            bit_pos = 4'd1;
                        end else begin // hdr_pixel_reg[0] must be 1
                            bit_pos = 4'd0;
                        end
                    end
                end
            end
            found = 1'b1;
        end
        
        log_result = {bit_pos, 4'b0};
    end
    
    // HDR to SDR conversion logic with method-based approach
    always @(*) begin
        // Default assignment
        sdr_pixel_reg = 8'h00;
        
        // Method-specific processing
        if (method_sel_reg == 2'b00) begin
            // Simple linear truncation
            sdr_pixel_reg = hdr_pixel_reg >> 8;
        end
        else if (method_sel_reg == 2'b01) begin
            // Log approximation
            sdr_pixel_reg = log_result;
        end
        else if (method_sel_reg == 2'b10) begin
            // Clipping
            if (hdr_pixel_reg > 16'h00FF) begin
                sdr_pixel_reg = 8'hFF;
            end else begin
                sdr_pixel_reg = hdr_pixel_reg[7:0];
            end
        end
        else if (method_sel_reg == 2'b11) begin
            // Custom scaling
            sdr_pixel_reg = ((hdr_pixel_reg * custom_param_reg) >> 8);
        end
    end
    
    // Output assignment
    assign sdr_pixel_out = sdr_pixel_reg;

endmodule