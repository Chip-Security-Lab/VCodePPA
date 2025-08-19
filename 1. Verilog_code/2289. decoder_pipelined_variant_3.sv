//SystemVerilog
module decoder_pipelined_axi (
    // Global signals
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // Write Response Channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // Read Address Channel
    input wire [31:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // Original decoded output (optional, can be removed if not needed externally)
    output wire [15:0] decoded_out
);

    // Internal registers
    reg [3:0] addr_reg;
    reg [15:0] decoded_reg;
    
    // AXI state machine states
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;
    localparam RESP = 2'b11;
    
    // State registers
    reg [1:0] write_state;
    reg [1:0] read_state;
    reg [3:0] addr_value;
    
    // Constants
    localparam ADDR_OFFSET = 2'h0;     // Register address offset
    localparam AXI_OKAY = 2'b00;       // AXI okay response
    localparam AXI_SLVERR = 2'b10;     // AXI slave error response
    
    // Core decoder functionality
    always @(posedge aclk) begin
        if (!aresetn) begin
            addr_reg <= 4'h0;
            decoded_reg <= 16'h0;
        end else begin
            addr_reg <= addr_value;
            decoded_reg <= 1'b1 << addr_reg;
        end
    end
    
    // Connect to output
    assign decoded_out = decoded_reg;
    
    // AXI4-Lite Write Channel state machine
    always @(posedge aclk) begin
        if (!aresetn) begin
            write_state <= IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= AXI_OKAY;
        end else begin
            case (write_state)
                IDLE: begin
                    // Ready to accept address
                    s_axi_awready <= 1'b1;
                    s_axi_wready <= 1'b0;
                    s_axi_bvalid <= 1'b0;
                    
                    if (s_axi_awvalid && s_axi_awready) begin
                        if (s_axi_awaddr[7:0] == ADDR_OFFSET) begin
                            write_state <= ADDR;
                            s_axi_awready <= 1'b0;
                            s_axi_wready <= 1'b1;
                        end else begin
                            // Invalid address
                            write_state <= RESP;
                            s_axi_awready <= 1'b0;
                            s_axi_bresp <= AXI_SLVERR;
                            s_axi_bvalid <= 1'b1;
                        end
                    end
                end
                
                ADDR: begin
                    // Ready to accept data
                    if (s_axi_wvalid && s_axi_wready) begin
                        addr_value <= s_axi_wdata[3:0];
                        s_axi_wready <= 1'b0;
                        s_axi_bresp <= AXI_OKAY;
                        s_axi_bvalid <= 1'b1;
                        write_state <= RESP;
                    end
                end
                
                RESP: begin
                    // Complete write transaction
                    if (s_axi_bready && s_axi_bvalid) begin
                        s_axi_bvalid <= 1'b0;
                        write_state <= IDLE;
                        s_axi_awready <= 1'b1;
                    end
                end
                
                default: write_state <= IDLE;
            endcase
        end
    end
    
    // AXI4-Lite Read Channel state machine
    always @(posedge aclk) begin
        if (!aresetn) begin
            read_state <= IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= AXI_OKAY;
            s_axi_rdata <= 32'h0;
        end else begin
            case (read_state)
                IDLE: begin
                    // Ready to accept address
                    s_axi_arready <= 1'b1;
                    s_axi_rvalid <= 1'b0;
                    
                    if (s_axi_arvalid && s_axi_arready) begin
                        s_axi_arready <= 1'b0;
                        
                        if (s_axi_araddr[7:0] == ADDR_OFFSET) begin
                            // Valid address, prepare read data
                            s_axi_rdata <= {28'h0, addr_reg};
                            s_axi_rresp <= AXI_OKAY;
                            read_state <= DATA;
                        end else if (s_axi_araddr[7:0] == ADDR_OFFSET + 4) begin
                            // Read decoded output
                            s_axi_rdata <= {16'h0, decoded_reg};
                            s_axi_rresp <= AXI_OKAY;
                            read_state <= DATA;
                        end else begin
                            // Invalid address
                            s_axi_rresp <= AXI_SLVERR;
                            read_state <= DATA;
                        end
                        
                        s_axi_rvalid <= 1'b1;
                    end
                end
                
                DATA: begin
                    // Complete read transaction
                    if (s_axi_rready && s_axi_rvalid) begin
                        s_axi_rvalid <= 1'b0;
                        read_state <= IDLE;
                        s_axi_arready <= 1'b1;
                    end
                end
                
                default: read_state <= IDLE;
            endcase
        end
    end

endmodule