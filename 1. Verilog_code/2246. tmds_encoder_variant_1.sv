//SystemVerilog
module tmds_encoder_axi (
    // AXI4-Lite interface
    input wire aclk,                      // Clock
    input wire aresetn,                   // Active low reset
    
    // Write address channel
    input wire [31:0] s_axi_awaddr,       // Write address
    input wire s_axi_awvalid,             // Write address valid
    output wire s_axi_awready,            // Write address ready
    
    // Write data channel
    input wire [31:0] s_axi_wdata,        // Write data
    input wire [3:0] s_axi_wstrb,         // Write strobe
    input wire s_axi_wvalid,              // Write valid
    output wire s_axi_wready,             // Write ready
    
    // Write response channel
    output wire [1:0] s_axi_bresp,        // Write response
    output wire s_axi_bvalid,             // Write response valid
    input wire s_axi_bready,              // Response ready
    
    // Read address channel
    input wire [31:0] s_axi_araddr,       // Read address
    input wire s_axi_arvalid,             // Read address valid
    output wire s_axi_arready,            // Read address ready
    
    // Read data channel
    output wire [31:0] s_axi_rdata,       // Read data
    output wire [1:0] s_axi_rresp,        // Read response
    output wire s_axi_rvalid,             // Read valid
    input wire s_axi_rready,              // Read ready
    
    // TMDS output
    output wire [9:0] encoded_out
);

    // Module interconnect signals
    wire [7:0] pixel_data;
    wire hsync, vsync, active;
    wire [9:0] encoded_data;
    
    // Register addresses (byte addressable)
    localparam ADDR_PIXEL_DATA = 4'h0;    // 0x00
    localparam ADDR_CONTROL    = 4'h4;    // 0x04
    localparam ADDR_ENCODED    = 4'h8;    // 0x08

    // Instantiate AXI slave interface module
    axi_slave_interface #(
        .ADDR_PIXEL_DATA(ADDR_PIXEL_DATA),
        .ADDR_CONTROL(ADDR_CONTROL),
        .ADDR_ENCODED(ADDR_ENCODED)
    ) axi_slave_inst (
        .aclk(aclk),
        .aresetn(aresetn),
        
        // Write channels
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        
        // Read channels
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        
        // Register interface
        .pixel_data_out(pixel_data),
        .hsync_out(hsync),
        .vsync_out(vsync),
        .active_out(active),
        .encoded_in(encoded_data)
    );
    
    // Instantiate TMDS encoder module
    tmds_encoder tmds_encoder_inst (
        .aclk(aclk),
        .aresetn(aresetn),
        .pixel_data(pixel_data),
        .hsync(hsync),
        .vsync(vsync),
        .active(active),
        .encoded_out(encoded_data)
    );
    
    // Register the encoded output
    tmds_output_register tmds_output_reg_inst (
        .aclk(aclk),
        .aresetn(aresetn),
        .encoded_in(encoded_data),
        .encoded_out(encoded_out)
    );

endmodule

//------------------------------------------------
// AXI Slave Interface Module
//------------------------------------------------
module axi_slave_interface #(
    parameter ADDR_PIXEL_DATA = 4'h0,
    parameter ADDR_CONTROL = 4'h4,
    parameter ADDR_ENCODED = 4'h8
)(
    // AXI4-Lite interface
    input wire aclk,
    input wire aresetn,
    
    // Write address channel
    input wire [31:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // Write data channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // Write response channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // Read address channel
    input wire [31:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // Read data channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // Register interface
    output reg [7:0] pixel_data_out,
    output reg hsync_out,
    output reg vsync_out,
    output reg active_out,
    input wire [9:0] encoded_in
);

    // AXI write states
    localparam WRITE_IDLE = 2'h0;
    localparam WRITE_DATA = 2'h1;
    localparam WRITE_RESP = 2'h2;
    reg [1:0] write_state;
    
    // AXI read states
    localparam READ_IDLE = 2'h0;
    localparam READ_DATA = 2'h1;
    reg [1:0] read_state;
    
    // AXI address registers
    reg [3:0] write_addr;
    reg [3:0] read_addr;
    
    // AXI4-Lite write channel
    always @(posedge aclk) begin
        if (!aresetn) begin
            pixel_data_out <= 8'h0;
            hsync_out <= 1'b0;
            vsync_out <= 1'b0;
            active_out <= 1'b0;
            
            write_state <= WRITE_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00; // OKAY
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    if (s_axi_awvalid && !s_axi_awready) begin
                        s_axi_awready <= 1'b1;
                        write_addr <= s_axi_awaddr[5:2]; // Word aligned address
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    s_axi_awready <= 1'b0;
                    
                    if (s_axi_wvalid && !s_axi_wready) begin
                        s_axi_wready <= 1'b1;
                        
                        case (write_addr)
                            ADDR_PIXEL_DATA: begin
                                if (s_axi_wstrb[0]) pixel_data_out <= s_axi_wdata[7:0];
                            end
                            ADDR_CONTROL: begin
                                if (s_axi_wstrb[0]) begin
                                    hsync_out <= s_axi_wdata[0];
                                    vsync_out <= s_axi_wdata[1];
                                    active_out <= s_axi_wdata[2];
                                end
                            end
                            default: begin
                                // Read-only or invalid address
                            end
                        endcase
                        
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    s_axi_wready <= 1'b0;
                    s_axi_bvalid <= 1'b1;
                    
                    if (s_axi_bready && s_axi_bvalid) begin
                        s_axi_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // AXI4-Lite read channel
    always @(posedge aclk) begin
        if (!aresetn) begin
            read_state <= READ_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'h0;
            s_axi_rresp <= 2'b00; // OKAY
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (s_axi_arvalid && !s_axi_arready) begin
                        s_axi_arready <= 1'b1;
                        read_addr <= s_axi_araddr[5:2]; // Word aligned address
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    s_axi_arready <= 1'b0;
                    s_axi_rvalid <= 1'b1;
                    
                    case (read_addr)
                        ADDR_PIXEL_DATA: begin
                            s_axi_rdata <= {24'h0, pixel_data_out};
                        end
                        ADDR_CONTROL: begin
                            s_axi_rdata <= {29'h0, active_out, vsync_out, hsync_out};
                        end
                        ADDR_ENCODED: begin
                            s_axi_rdata <= {22'h0, encoded_in};
                        end
                        default: begin
                            s_axi_rdata <= 32'h0;
                            s_axi_rresp <= 2'b10; // SLVERR for invalid address
                        end
                    endcase
                    
                    if (s_axi_rready && s_axi_rvalid) begin
                        s_axi_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end

endmodule

//------------------------------------------------
// TMDS Encoder Module
//------------------------------------------------
module tmds_encoder (
    input wire aclk,
    input wire aresetn,
    input wire [7:0] pixel_data,
    input wire hsync,
    input wire vsync,
    input wire active,
    output reg [9:0] encoded_out
);
    
    // Count ones in pixel data for TMDS encoding
    function [3:0] count_ones;
        input [7:0] data;
        integer i;
        begin
            count_ones = 0;
            for (i = 0; i < 8; i = i + 1) begin
                count_ones = count_ones + data[i];
            end
        end
    endfunction
    
    // TMDS encoding logic
    wire [3:0] ones = count_ones(pixel_data);
    wire use_xnor = ones > 4'd4 || (ones == 4'd4 && !pixel_data[0]);
    
    // Encode data based on input conditions
    always @(*) begin
        case({active, use_xnor})
            2'b11 : encoded_out = {~pixel_data[7], pixel_data[6:0] ^ {7{pixel_data[7]}}};
            2'b10 : encoded_out = {pixel_data[7], pixel_data[6:0] ^ {7{~pixel_data[7]}}};
            2'b01, 2'b00 : encoded_out = {2'b01, hsync, vsync, 6'b000000};
        endcase
    end

endmodule

//------------------------------------------------
// TMDS Output Register Module
//------------------------------------------------
module tmds_output_register (
    input wire aclk,
    input wire aresetn,
    input wire [9:0] encoded_in,
    output reg [9:0] encoded_out
);

    // Register the encoded output
    always @(posedge aclk) begin
        if (!aresetn) begin
            encoded_out <= 10'b0;
        end else begin
            encoded_out <= encoded_in;
        end
    end

endmodule