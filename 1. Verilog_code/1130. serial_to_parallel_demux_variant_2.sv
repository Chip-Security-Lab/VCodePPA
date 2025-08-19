//SystemVerilog
module serial_to_parallel_demux (
    // Clock and Reset
    input wire aclk,                         // AXI Clock signal
    input wire aresetn,                      // AXI Reset signal (active low)
    
    // Serial input
    input wire serial_in,                    // Serial data input
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,        // Write address
    input wire [2:0] s_axil_awprot,         // Write protection type
    input wire s_axil_awvalid,              // Write address valid
    output reg s_axil_awready,              // Write address ready
    
    // Write Data Channel
    input wire [31:0] s_axil_wdata,         // Write data
    input wire [3:0] s_axil_wstrb,          // Write strobes
    input wire s_axil_wvalid,               // Write valid
    output reg s_axil_wready,               // Write ready
    
    // Write Response Channel
    output reg [1:0] s_axil_bresp,          // Write response
    output reg s_axil_bvalid,               // Write response valid
    input wire s_axil_bready,               // Response ready
    
    // Read Address Channel
    input wire [31:0] s_axil_araddr,        // Read address
    input wire [2:0] s_axil_arprot,         // Read protection type
    input wire s_axil_arvalid,              // Read address valid
    output reg s_axil_arready,              // Read address ready
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,         // Read data
    output reg [1:0] s_axil_rresp,          // Read response
    output reg s_axil_rvalid,               // Read valid
    input wire s_axil_rready                // Read ready
);

    // Internal registers
    reg [7:0] parallel_out;                 // Parallel output register
    reg [2:0] bit_counter;                  // Bit position counter
    reg load_enable;                        // Load control register
    
    // AXI4-Lite address decode parameters - using 2-bit addressing for optimal comparison
    localparam [1:0] ADDR_PARALLEL_OUT = 2'b00;    // Address for parallel output register
    localparam [1:0] ADDR_CONTROL      = 2'b01;    // Address for control register
    localparam [1:0] ADDR_STATUS       = 2'b10;    // Address for status register
    
    // AXI response definitions
    localparam [1:0] RESP_OKAY   = 2'b00;
    localparam [1:0] RESP_EXOKAY = 2'b01;
    localparam [1:0] RESP_SLVERR = 2'b10;
    localparam [1:0] RESP_DECERR = 2'b11;
    
    // State definitions for AXI write transactions
    reg write_state;
    localparam WRITE_IDLE = 1'b0;
    localparam WRITE_RESP = 1'b1;
    
    // State definitions for AXI read transactions
    reg read_state;
    localparam READ_IDLE = 1'b0;
    localparam READ_RESP = 1'b1;
    
    // Write address and data latches
    reg [1:0] write_addr;  // Optimized to use only 2 bits
    reg [31:0] write_data;
    
    // Read address latch
    reg [1:0] read_addr;   // Optimized to use only 2 bits
    
    // Status register
    wire [31:0] status_reg;
    assign status_reg = {29'b0, bit_counter};
    
    // Main serial-to-parallel conversion logic
    always @(posedge aclk) begin
        if (!aresetn) begin
            bit_counter <= 3'b0;
            parallel_out <= 8'b0;
        end else if (load_enable) begin
            parallel_out[bit_counter] <= serial_in;
            bit_counter <= bit_counter + 1'b1;
        end
    end
    
    // Write channels handshake signals
    wire aw_hs = s_axil_awvalid && s_axil_awready;
    wire w_hs = s_axil_wvalid && s_axil_wready;
    wire both_valid = s_axil_awvalid && s_axil_wvalid;
    
    // AXI4-Lite Write channels controller - optimized state machine
    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= RESP_OKAY;
            write_state <= WRITE_IDLE;
            load_enable <= 1'b0;
            write_addr <= 2'b0;
            write_data <= 32'h0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    // Optimize by checking both valid signals first for fast path
                    if (both_valid && !(s_axil_awready || s_axil_wready)) begin
                        s_axil_awready <= 1'b1;
                        s_axil_wready <= 1'b1;
                        write_addr <= s_axil_awaddr[3:2]; // Only use bits [3:2] for more efficient register addressing
                        write_data <= s_axil_wdata;
                        write_state <= WRITE_RESP;
                    end else begin
                        // Handle individual channel handshakes
                        if (s_axil_awvalid && !s_axil_awready) begin
                            s_axil_awready <= 1'b1;
                            write_addr <= s_axil_awaddr[3:2];
                        end else begin
                            s_axil_awready <= 1'b0;
                        end
                        
                        if (s_axil_wvalid && !s_axil_wready) begin
                            s_axil_wready <= 1'b1;
                            write_data <= s_axil_wdata;
                        end else begin
                            s_axil_wready <= 1'b0;
                        end
                        
                        // When both handshakes complete, move to response
                        if ((s_axil_awready && s_axil_awvalid) && (s_axil_wready && s_axil_wvalid)) begin
                            write_state <= WRITE_RESP;
                            s_axil_awready <= 1'b0;
                            s_axil_wready <= 1'b0;
                            s_axil_bvalid <= 1'b1;
                            
                            // Process write based on optimized address decoding
                            if (write_addr == ADDR_CONTROL) begin
                                load_enable <= write_data[0];
                                s_axil_bresp <= RESP_OKAY;
                            end else begin
                                s_axil_bresp <= RESP_DECERR;
                            end
                        end
                    end
                end
                
                WRITE_RESP: begin
                    // Reset awready and wready
                    s_axil_awready <= 1'b0;
                    s_axil_wready <= 1'b0;
                    
                    // Wait for master to accept response
                    if (s_axil_bready) begin
                        s_axil_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // AXI4-Lite Read channels controller - optimized address decode
    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= RESP_OKAY;
            s_axil_rdata <= 32'h0;
            read_state <= READ_IDLE;
            read_addr <= 2'b0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (s_axil_arvalid) begin
                        s_axil_arready <= 1'b1;
                        read_addr <= s_axil_araddr[3:2]; // Using bits [3:2] for more efficient register addressing
                        read_state <= READ_RESP;
                    end
                end
                
                READ_RESP: begin
                    s_axil_arready <= 1'b0;
                    s_axil_rvalid <= 1'b1;
                    
                    // Optimized address decode using binary comparison tree
                    case (read_addr)
                        ADDR_PARALLEL_OUT: begin
                            s_axil_rdata <= {24'b0, parallel_out};
                            s_axil_rresp <= RESP_OKAY;
                        end
                        ADDR_CONTROL: begin
                            s_axil_rdata <= {31'b0, load_enable};
                            s_axil_rresp <= RESP_OKAY;
                        end
                        ADDR_STATUS: begin
                            s_axil_rdata <= status_reg;
                            s_axil_rresp <= RESP_OKAY;
                        end
                        default: begin
                            s_axil_rdata <= 32'h0;
                            s_axil_rresp <= RESP_DECERR;
                        end
                    endcase
                    
                    // Transition back to IDLE when read is complete
                    if (s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end

endmodule