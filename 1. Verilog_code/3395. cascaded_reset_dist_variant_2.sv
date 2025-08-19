//SystemVerilog
module cascaded_reset_dist (
    // Clock and Reset
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input wire [31:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // Module outputs
    output wire [3:0] rst_cascade
);

    // Internal registers
    reg [3:0] rst_reg;
    reg rst_in;
    
    // Register address definitions - word aligned and using mask for efficient comparison
    localparam ADDR_RST_IN = 4'h0;     // Control register for rst_in
    localparam ADDR_RST_CASCADE = 4'h4; // Status register for rst_cascade
    
    // AXI state encoding for one-hot encoding to improve timing
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_DATA = 2'b01;
    localparam WRITE_RESP = 2'b10;
    
    localparam READ_IDLE = 2'b00;
    localparam READ_DATA = 2'b01;
    
    // State registers
    reg [1:0] write_state;
    reg [1:0] read_state;
    
    // Address registers
    reg [3:0] write_addr, read_addr;
    
    // Core functionality - Cascaded reset with optimized shift register
    // Efficiently shifts reset values through cascade
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn || rst_in)
            rst_reg <= 4'b1111;
        else
            rst_reg <= {1'b0, rst_reg[3:1]};
    end
    
    assign rst_cascade = rst_reg;
    
    // AXI Write Channel State Machine - Optimized state transitions
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            write_state <= WRITE_IDLE;
            write_addr <= 4'h0;
            s_axi_awready <= 1'b1;  // Ready to accept address in reset state
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            rst_in <= 1'b0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    if (s_axi_awvalid) begin
                        write_addr <= s_axi_awaddr[5:2];
                        s_axi_awready <= 1'b0;
                        s_axi_wready <= 1'b1;
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b0;
                        s_axi_bvalid <= 1'b1;
                        
                        // Simplified address comparison using equality check
                        if (write_addr == ADDR_RST_IN) begin
                            if (s_axi_wstrb[0])
                                rst_in <= s_axi_wdata[0];
                            s_axi_bresp <= 2'b00;  // OKAY response
                        end else begin
                            // Invalid address
                            s_axi_bresp <= 2'b10;  // SLVERR response
                        end
                        
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        s_axi_awready <= 1'b1;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // AXI Read Channel State Machine - Optimized state transitions
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            read_state <= READ_IDLE;
            read_addr <= 4'h0;
            s_axi_arready <= 1'b1;  // Ready to accept address in reset state
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            s_axi_rdata <= 32'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (s_axi_arvalid) begin
                        read_addr <= s_axi_araddr[5:2];
                        s_axi_arready <= 1'b0;
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    s_axi_rvalid <= 1'b1;
                    
                    // Optimized address comparison using efficient branching
                    case (read_addr)
                        ADDR_RST_IN: begin
                            s_axi_rdata <= {31'b0, rst_in};
                            s_axi_rresp <= 2'b00;  // OKAY response
                        end
                        ADDR_RST_CASCADE: begin
                            s_axi_rdata <= {28'b0, rst_cascade};
                            s_axi_rresp <= 2'b00;  // OKAY response
                        end
                        default: begin
                            s_axi_rdata <= 32'h0;
                            s_axi_rresp <= 2'b10;  // SLVERR response
                        end
                    endcase
                    
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        s_axi_arready <= 1'b1;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end

endmodule