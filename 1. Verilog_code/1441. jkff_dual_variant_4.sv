//SystemVerilog
module jkff_dual_axi4lite (
    // Global Signals
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite Slave Interface - Write Address Channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    
    // AXI4-Lite Slave Interface - Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    
    // AXI4-Lite Slave Interface - Write Response Channel
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite Slave Interface - Read Address Channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    
    // AXI4-Lite Slave Interface - Read Data Channel
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // Status Output
    output wire        q_out
);

    // Register Address Map (Byte Addresses)
    localparam ADDR_JK_CONTROL = 4'h0;    // J (bit 1), K (bit 0)
    localparam ADDR_STATUS     = 4'h4;    // Q output (bit 0)
    
    // Internal signals
    reg  j_reg, k_reg;
    reg  q_pos, q_neg;
    wire set_pos, reset_pos, toggle_pos, no_change_pos;
    wire set_neg, reset_neg, toggle_neg, no_change_neg;
    
    // AXI4-Lite FSM states
    localparam IDLE        = 2'b00;
    localparam WRITE_PHASE = 2'b01;
    localparam READ_PHASE  = 2'b10;
    reg [1:0] axi_state;
    
    // Write address capture
    reg [3:0] write_addr;
    reg       write_addr_valid;
    
    // Read address capture
    reg [3:0] read_addr;
    reg       read_addr_valid;
    
    // AXI4-Lite interface logic
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_state        <= IDLE;
            s_axi_awready    <= 1'b0;
            s_axi_wready     <= 1'b0;
            s_axi_bvalid     <= 1'b0;
            s_axi_bresp      <= 2'b00;
            s_axi_arready    <= 1'b0;
            s_axi_rvalid     <= 1'b0;
            s_axi_rresp      <= 2'b00;
            s_axi_rdata      <= 32'h0;
            write_addr       <= 4'h0;
            write_addr_valid <= 1'b0;
            read_addr        <= 4'h0;
            read_addr_valid  <= 1'b0;
            j_reg            <= 1'b0;
            k_reg            <= 1'b0;
        end
        else begin
            case (axi_state)
                IDLE: begin
                    // Default is to clear ready/valid signals
                    s_axi_bvalid  <= 1'b0;
                    s_axi_rvalid  <= 1'b0;
                    
                    // Write address channel
                    if (s_axi_awvalid && !write_addr_valid) begin
                        s_axi_awready    <= 1'b1;
                        write_addr       <= s_axi_awaddr[3:0]; // Only use lower 4 bits of address
                        write_addr_valid <= 1'b1;
                    end
                    else begin
                        s_axi_awready <= 1'b0;
                    end
                    
                    // Write data channel - once we have address, accept data
                    if (s_axi_wvalid && write_addr_valid) begin
                        s_axi_wready  <= 1'b1;
                        axi_state     <= WRITE_PHASE;
                    end
                    else begin
                        s_axi_wready  <= 1'b0;
                    end
                    
                    // Read address channel - higher priority than write
                    if (s_axi_arvalid) begin
                        s_axi_arready   <= 1'b1;
                        read_addr       <= s_axi_araddr[3:0]; // Only use lower 4 bits of address
                        read_addr_valid <= 1'b1;
                        axi_state       <= READ_PHASE;
                    end
                    else begin
                        s_axi_arready   <= 1'b0;
                    end
                end
                
                WRITE_PHASE: begin
                    // Clear handshake signals
                    s_axi_awready <= 1'b0;
                    s_axi_wready  <= 1'b0;
                    
                    // Process write based on address
                    if (write_addr == ADDR_JK_CONTROL && s_axi_wstrb[0]) begin
                        j_reg <= s_axi_wdata[1];
                        k_reg <= s_axi_wdata[0];
                    end
                    
                    // Send write response
                    s_axi_bvalid <= 1'b1;
                    s_axi_bresp  <= 2'b00; // OKAY response
                    
                    // Wait for response handshake
                    if (s_axi_bvalid && s_axi_bready) begin
                        s_axi_bvalid     <= 1'b0;
                        write_addr_valid <= 1'b0;
                        axi_state        <= IDLE;
                    end
                end
                
                READ_PHASE: begin
                    // Clear handshake signals
                    s_axi_arready <= 1'b0;
                    
                    // Process read based on address
                    s_axi_rvalid <= 1'b1;
                    s_axi_rresp  <= 2'b00; // OKAY response
                    
                    case (read_addr)
                        ADDR_JK_CONTROL: s_axi_rdata <= {30'h0, j_reg, k_reg};
                        ADDR_STATUS:     s_axi_rdata <= {31'h0, q_out};
                        default:         s_axi_rdata <= 32'h0;
                    endcase
                    
                    // Wait for response handshake
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid    <= 1'b0;
                        read_addr_valid <= 1'b0;
                        axi_state       <= IDLE;
                    end
                end
                
                default: axi_state <= IDLE;
            endcase
        end
    end
    
    // JK flip-flop control signals
    assign set_pos = j_reg && !k_reg;
    assign reset_pos = !j_reg && k_reg;
    assign toggle_pos = j_reg && k_reg;
    assign no_change_pos = !j_reg && !k_reg;
    
    assign set_neg = j_reg && !k_reg;
    assign reset_neg = !j_reg && k_reg;
    assign toggle_neg = j_reg && k_reg;
    assign no_change_neg = !j_reg && !k_reg;
    
    // Positive edge FF state logic
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) 
            q_pos <= 1'b0;
        else if (set_pos)
            q_pos <= 1'b1;
        else if (reset_pos)
            q_pos <= 1'b0;
        else if (toggle_pos)
            q_pos <= ~q_pos;
        else // no_change_pos
            q_pos <= q_pos;
    end
    
    // Negative edge FF state logic
    always @(negedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) 
            q_neg <= 1'b0;
        else if (set_neg)
            q_neg <= 1'b1;
        else if (reset_neg)
            q_neg <= 1'b0;
        else if (toggle_neg)
            q_neg <= ~q_neg;
        else // no_change_neg
            q_neg <= q_neg;
    end
    
    // Output multiplexing based on clock value
    assign q_out = s_axi_aclk ? q_pos : q_neg;
    
endmodule