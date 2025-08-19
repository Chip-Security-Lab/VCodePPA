//SystemVerilog
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module dynamic_reset_path (
    // Global signals
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite slave interface
    // Write address channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    
    // Write data channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    
    // Write response channel
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // Read address channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    
    // Read data channel
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // Original module IO
    input  wire [3:0]  reset_sources,
    output reg         reset_out
);

    // Register definitions
    reg [1:0] path_select;
    reg [3:0] reset_sources_reg;
    
    // AXI4-Lite address mapping (byte-addressed)
    localparam ADDR_PATH_SELECT   = 32'h0000_0000;
    localparam ADDR_RESET_SOURCES = 32'h0000_0004;
    localparam ADDR_RESET_OUT     = 32'h0000_0008;
    
    // AXI4-Lite response codes
    localparam RESP_OKAY   = 2'b00;
    localparam RESP_SLVERR = 2'b10;
    
    // Internal signals
    reg [31:0] read_addr;
    reg [31:0] write_addr;
    reg [31:0] write_data;
    reg [3:0]  write_strb;
    
    // Write transaction FSM
    reg [1:0] write_state;
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_DATA = 2'b01;
    localparam WRITE_RESP = 2'b10;
    
    // Read transaction FSM
    reg [1:0] read_state;
    localparam READ_IDLE = 2'b00;
    localparam READ_DATA = 2'b01;
    
    // Pipelined reset sources
    reg [3:0] reset_sources_stage1;
    reg [3:0] reset_sources_stage2;
    
    // Reset output pipeline
    reg reset_mux_out;
    
    // Write channel state machine
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            write_state <= WRITE_IDLE;
            write_addr <= 32'h0;
            write_data <= 32'h0;
            write_strb <= 4'h0;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= RESP_OKAY;
            path_select <= 2'b00;
            reset_sources_reg <= 4'h0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    // Accept address
                    if (s_axi_awvalid && !s_axi_awready) begin
                        s_axi_awready <= 1'b1;
                        write_addr <= s_axi_awaddr;
                    end
                    
                    // Accept data
                    if (s_axi_wvalid && !s_axi_wready) begin
                        s_axi_wready <= 1'b1;
                        write_data <= s_axi_wdata;
                        write_strb <= s_axi_wstrb;
                    end
                    
                    // If both address and data received, process write
                    if (s_axi_awready && s_axi_wready) begin
                        s_axi_awready <= 1'b0;
                        s_axi_wready <= 1'b0;
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    // Process the write data
                    case (write_addr)
                        ADDR_PATH_SELECT: begin
                            if (write_strb[0]) path_select <= write_data[1:0];
                            s_axi_bresp <= RESP_OKAY;
                        end
                        ADDR_RESET_SOURCES: begin
                            if (write_strb[0]) reset_sources_reg <= write_data[3:0];
                            s_axi_bresp <= RESP_OKAY;
                        end
                        default: begin
                            // Address not recognized
                            s_axi_bresp <= RESP_SLVERR;
                        end
                    endcase
                    
                    s_axi_bvalid <= 1'b1;
                    write_state <= WRITE_RESP;
                end
                
                WRITE_RESP: begin
                    // Wait for response handshake
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: begin
                    write_state <= WRITE_IDLE;
                end
            endcase
        end
    end
    
    // Read channel state machine
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            read_state <= READ_IDLE;
            read_addr <= 32'h0;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'h0;
            s_axi_rresp <= RESP_OKAY;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    // Accept address
                    if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b1;
                        read_addr <= s_axi_araddr;
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    s_axi_arready <= 1'b0;
                    
                    // Decode address and prepare data
                    case (read_addr)
                        ADDR_PATH_SELECT: begin
                            s_axi_rdata <= {30'b0, path_select};
                            s_axi_rresp <= RESP_OKAY;
                        end
                        ADDR_RESET_SOURCES: begin
                            s_axi_rdata <= {28'b0, reset_sources_stage2};
                            s_axi_rresp <= RESP_OKAY;
                        end
                        ADDR_RESET_OUT: begin
                            s_axi_rdata <= {31'b0, reset_out};
                            s_axi_rresp <= RESP_OKAY;
                        end
                        default: begin
                            // Address not recognized
                            s_axi_rdata <= 32'h0;
                            s_axi_rresp <= RESP_SLVERR;
                        end
                    endcase
                    
                    s_axi_rvalid <= 1'b1;
                    
                    // Wait for response handshake
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: begin
                    read_state <= READ_IDLE;
                end
            endcase
        end
    end
    
    // Pipeline the reset_sources input for better timing
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            reset_sources_stage1 <= 4'b0000;
            reset_sources_stage2 <= 4'b0000;
        end else begin
            reset_sources_stage1 <= reset_sources;
            reset_sources_stage2 <= reset_sources_stage1;
        end
    end
    
    // Core functionality - Reset path selection
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            reset_mux_out <= 1'b0;
        end else begin
            case (path_select)
                2'b00: reset_mux_out <= reset_sources_stage2[0];
                2'b01: reset_mux_out <= reset_sources_stage2[1];
                2'b10: reset_mux_out <= reset_sources_stage2[2];
                2'b11: reset_mux_out <= reset_sources_stage2[3];
            endcase
        end
    end
    
    // Register the output for better timing
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            reset_out <= 1'b0;
        end else begin
            reset_out <= reset_mux_out;
        end
    end

endmodule