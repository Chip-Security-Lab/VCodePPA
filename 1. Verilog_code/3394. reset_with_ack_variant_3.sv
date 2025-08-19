//SystemVerilog
module reset_with_ack (
    input wire clk,
    input wire aresetn,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input  wire [31:0] s_axil_awaddr,
    input  wire [2:0]  s_axil_awprot,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    
    // Write Data Channel
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    
    // Write Response Channel
    output wire [1:0]  s_axil_bresp,
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,
    
    // Read Address Channel
    input  wire [31:0] s_axil_araddr,
    input  wire [2:0]  s_axil_arprot,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    
    // Read Data Channel
    output wire [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready
);

    // AXI4-Lite response codes
    localparam RESP_OKAY   = 2'b00;
    localparam RESP_EXOKAY = 2'b01;
    localparam RESP_SLVERR = 2'b10;
    localparam RESP_DECERR = 2'b11;

    // Register map
    localparam ADDR_CONTROL     = 4'h0;  // Control register
    localparam ADDR_STATUS      = 4'h4;  // Status register
    localparam ADDR_ACK_SIGNALS = 4'h8;  // Acknowledgment signals

    // Register values
    reg [3:0] control_reg;     // Control register for reset requests
    reg [3:0] status_reg;      // Status register
    reg [3:0] ack_signals_reg; // Register to store acknowledgment signals
    
    // Internal state signals
    reg reset_in_progress;
    reg reset_complete;
    
    // AXI4-Lite interface signals
    reg  s_axil_awready_reg;
    reg  s_axil_wready_reg;
    reg  s_axil_bvalid_reg;
    reg  [1:0] s_axil_bresp_reg;
    reg  s_axil_arready_reg;
    reg  s_axil_rvalid_reg;
    reg  [1:0] s_axil_rresp_reg;
    reg  [31:0] s_axil_rdata_reg;
    
    // Write Address Channel handshake
    assign s_axil_awready = s_axil_awready_reg;
    
    // Write Data Channel handshake
    assign s_axil_wready = s_axil_wready_reg;
    
    // Write Response Channel
    assign s_axil_bvalid = s_axil_bvalid_reg;
    assign s_axil_bresp = s_axil_bresp_reg;
    
    // Read Address Channel handshake
    assign s_axil_arready = s_axil_arready_reg;
    
    // Read Data Channel
    assign s_axil_rvalid = s_axil_rvalid_reg;
    assign s_axil_rresp = s_axil_rresp_reg;
    assign s_axil_rdata = s_axil_rdata_reg;

    // Write state machine
    reg [1:0] write_state;
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    // Read state machine
    reg [1:0] read_state;
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    // Store write address
    reg [3:0] write_addr;
    
    // Write state machine
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= WRITE_IDLE;
            s_axil_awready_reg <= 1'b0;
            s_axil_wready_reg <= 1'b0;
            s_axil_bvalid_reg <= 1'b0;
            s_axil_bresp_reg <= RESP_OKAY;
            write_addr <= 4'h0;
            control_reg <= 4'h0;
            ack_signals_reg <= 4'h0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    // Ready to accept address
                    s_axil_awready_reg <= 1'b1;
                    s_axil_wready_reg <= 1'b0;
                    s_axil_bvalid_reg <= 1'b0;
                    
                    if (s_axil_awvalid && s_axil_awready) begin
                        // Capture the write address
                        write_addr <= s_axil_awaddr[3:0]; // Use lower 4 bits for register addressing
                        s_axil_awready_reg <= 1'b0;
                        s_axil_wready_reg <= 1'b1;
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    // Ready to accept data
                    if (s_axil_wvalid && s_axil_wready) begin
                        s_axil_wready_reg <= 1'b0;
                        s_axil_bvalid_reg <= 1'b1;
                        s_axil_bresp_reg <= RESP_OKAY;
                        
                        // Process write data based on address
                        case (write_addr)
                            ADDR_CONTROL: begin
                                // Handle control register write
                                control_reg <= s_axil_wdata[3:0];
                                
                                // Check for reset request (0xF)
                                if (s_axil_wdata[3:0] == 4'hF && !reset_in_progress) begin
                                    reset_in_progress <= 1'b1;
                                    ack_signals_reg <= 4'h0;
                                    status_reg <= 4'h1; // Indicate reset in progress
                                end
                            end
                            
                            ADDR_ACK_SIGNALS: begin
                                // Process acknowledgment if reset is in progress
                                if (reset_in_progress) begin
                                    ack_signals_reg <= s_axil_wdata[3:0];
                                    
                                    // Check if all acknowledgments received
                                    if (s_axil_wdata[3:0] == 4'hF) begin
                                        reset_in_progress <= 1'b0;
                                        reset_complete <= 1'b1;
                                        status_reg <= 4'h2; // Indicate reset complete
                                    end
                                end
                            end
                            
                            default: begin
                                // Invalid register address
                                s_axil_bresp_reg <= RESP_DECERR;
                            end
                        endcase
                        
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    // Wait for response to be accepted
                    if (s_axil_bready && s_axil_bvalid) begin
                        s_axil_bvalid_reg <= 1'b0;
                        write_state <= WRITE_IDLE;
                        s_axil_awready_reg <= 1'b1;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
            
            // Clear reset_complete flag after one cycle
            if (reset_complete) begin
                reset_complete <= 1'b0;
                status_reg <= 4'h0; // Return to idle state
            end
        end
    end
    
    // Read state machine
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= READ_IDLE;
            s_axil_arready_reg <= 1'b0;
            s_axil_rvalid_reg <= 1'b0;
            s_axil_rresp_reg <= RESP_OKAY;
            s_axil_rdata_reg <= 32'h0;
            status_reg <= 4'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    // Ready to accept read address
                    s_axil_arready_reg <= 1'b1;
                    s_axil_rvalid_reg <= 1'b0;
                    
                    if (s_axil_arvalid && s_axil_arready) begin
                        s_axil_arready_reg <= 1'b0;
                        
                        // Prepare data based on read address
                        case (s_axil_araddr[3:0])
                            ADDR_CONTROL: begin
                                s_axil_rdata_reg <= {28'h0, control_reg};
                                s_axil_rresp_reg <= RESP_OKAY;
                            end
                            
                            ADDR_STATUS: begin
                                s_axil_rdata_reg <= {28'h0, status_reg};
                                s_axil_rresp_reg <= RESP_OKAY;
                            end
                            
                            ADDR_ACK_SIGNALS: begin
                                s_axil_rdata_reg <= {28'h0, ack_signals_reg};
                                s_axil_rresp_reg <= RESP_OKAY;
                            end
                            
                            default: begin
                                // Invalid register address
                                s_axil_rdata_reg <= 32'h0;
                                s_axil_rresp_reg <= RESP_DECERR;
                            end
                        endcase
                        
                        s_axil_rvalid_reg <= 1'b1;
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    // Wait for read data to be accepted
                    if (s_axil_rready && s_axil_rvalid) begin
                        s_axil_rvalid_reg <= 1'b0;
                        read_state <= READ_IDLE;
                        s_axil_arready_reg <= 1'b1;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end

endmodule