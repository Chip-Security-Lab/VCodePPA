//SystemVerilog
module pipelined_decoder(
    // Global signals
    input wire clk,
    input wire resetn,
    
    // AXI4-Lite slave interface
    // Write address channel
    input wire [31:0] s_axil_awaddr,
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
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read data channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // Original decoder output (now available as read register)
    output reg [15:0] decode_out
);

    // Internal registers
    reg [3:0] addr_reg;
    reg [15:0] decode_reg;
    
    // AXI4-Lite write transaction states
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    reg [1:0] write_state;
    
    // AXI4-Lite read transaction states
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    reg [1:0] read_state;
    
    // Captured address
    reg [31:0] waddr;
    reg [31:0] raddr;
    
    // Write transaction state machine
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            write_state <= WRITE_IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bresp <= 2'b00; // OKAY
            s_axil_bvalid <= 1'b0;
            waddr <= 32'h0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b1;
                    if (s_axil_awvalid && s_axil_awready) begin
                        waddr <= s_axil_awaddr;
                        s_axil_awready <= 1'b0;
                        if (s_axil_wvalid) begin
                            // Both address and data are valid simultaneously
                            if (s_axil_awaddr[11:0] == 12'h000) begin
                                // Address register at offset 0x000
                                addr_reg <= s_axil_wdata[3:0];
                            end else begin
                                // Invalid address
                                s_axil_bresp <= 2'b10; // SLVERR
                            end
                            s_axil_wready <= 1'b0;
                            s_axil_bvalid <= 1'b1;
                            write_state <= WRITE_RESP;
                        end else begin
                            write_state <= WRITE_DATA;
                        end
                    end else if (s_axil_wvalid && s_axil_wready && !s_axil_awvalid) begin
                        // Data came first without address, wait for address
                        s_axil_wready <= 1'b0;
                        write_state <= WRITE_ADDR;
                    end
                end
                
                WRITE_ADDR: begin
                    s_axil_awready <= 1'b1;
                    if (s_axil_awvalid && s_axil_awready) begin
                        waddr <= s_axil_awaddr;
                        s_axil_awready <= 1'b0;
                        if (s_axil_awaddr[11:0] == 12'h000) begin
                            // Address register at offset 0x000
                            addr_reg <= s_axil_wdata[3:0];
                        end else begin
                            // Invalid address
                            s_axil_bresp <= 2'b10; // SLVERR
                        end
                        s_axil_bvalid <= 1'b1;
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_DATA: begin
                    s_axil_wready <= 1'b1;
                    if (s_axil_wvalid && s_axil_wready) begin
                        if (waddr[11:0] == 12'h000) begin
                            // Address register at offset 0x000
                            addr_reg <= s_axil_wdata[3:0];
                        end else begin
                            // Invalid address
                            s_axil_bresp <= 2'b10; // SLVERR
                        end
                        s_axil_wready <= 1'b0;
                        s_axil_bvalid <= 1'b1;
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready && s_axil_bvalid) begin
                        s_axil_bvalid <= 1'b0;
                        s_axil_bresp <= 2'b00; // Reset to OKAY
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: begin
                    write_state <= WRITE_IDLE;
                end
            endcase
        end
    end
    
    // Read transaction state machine
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            read_state <= READ_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00; // OKAY
            raddr <= 32'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    s_axil_arready <= 1'b1;
                    if (s_axil_arvalid && s_axil_arready) begin
                        raddr <= s_axil_araddr;
                        s_axil_arready <= 1'b0;
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    // Prepare read data
                    if (raddr[11:0] == 12'h000) begin
                        // Address register at offset 0x000
                        s_axil_rdata <= {28'h0, addr_reg};
                        s_axil_rresp <= 2'b00; // OKAY
                    end else if (raddr[11:0] == 12'h004) begin
                        // Decode output at offset 0x004
                        s_axil_rdata <= {16'h0, decode_out};
                        s_axil_rresp <= 2'b00; // OKAY
                    end else begin
                        // Invalid address
                        s_axil_rdata <= 32'h0;
                        s_axil_rresp <= 2'b10; // SLVERR
                    end
                    
                    s_axil_rvalid <= 1'b1;
                    
                    if (s_axil_rvalid && s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: begin
                    read_state <= READ_IDLE;
                end
            endcase
        end
    end
    
    // Decoder logic - synchronized to clock
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            decode_reg <= 16'h0;
            decode_out <= 16'h0;
        end else begin
            decode_reg <= (16'b1 << addr_reg);
            decode_out <= decode_reg;
        end
    end
    
endmodule