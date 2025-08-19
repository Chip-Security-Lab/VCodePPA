//SystemVerilog
module eth_full_duplex_controller (
    input wire clk,
    input wire rst_n,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);
    // State encoding optimization - one-hot encoding for better synthesis
    localparam IDLE     = 4'b0001;
    localparam TRANSMIT = 4'b0010;
    localparam PAUSE    = 4'b0100;
    localparam WAIT_IFG = 4'b1000;
    
    reg [3:0] state, next_state;
    reg [15:0] pause_counter, next_pause_counter;
    reg [3:0] ifg_counter, next_ifg_counter; // Reduced bit width
    
    localparam IFG_TIME = 4'd12; // 12 byte times for Inter-Frame Gap
    
    // AXI4-Lite internal signals and registers
    localparam ADDR_TX_REQUEST      = 4'h0;
    localparam ADDR_TX_COMPLETE     = 4'h1;
    localparam ADDR_PAUSE_FRAME_RX  = 4'h2;
    localparam ADDR_PAUSE_QUANTA_RX = 4'h3;
    localparam ADDR_BUFFER_STATUS   = 4'h4;
    localparam ADDR_TX_GRANT        = 4'h8;
    localparam ADDR_RX_ENABLE       = 4'h9;
    localparam ADDR_PAUSE_FRAME_TX  = 4'hA;
    localparam ADDR_PAUSE_QUANTA_TX = 4'hB;
    localparam ADDR_FLOW_CTRL_STAT  = 4'hC;
    
    // AXI response codes
    localparam RESP_OKAY   = 2'b00;
    localparam RESP_SLVERR = 2'b10;
    
    // Internal register for the original signals
    reg tx_request;
    reg tx_grant;
    reg tx_complete;
    reg rx_enable;
    reg pause_frame_rx;
    reg [15:0] pause_quanta_rx;
    reg pause_frame_tx;
    reg [15:0] pause_quanta_tx;
    reg rx_buffer_almost_full;
    reg flow_control_active;
    
    // AXI4-Lite write FSM
    reg [1:0] write_state, next_write_state;
    localparam W_IDLE = 2'b00;
    localparam W_DATA = 2'b01;
    localparam W_RESP = 2'b10;
    
    reg [3:0] waddr_reg;
    reg [31:0] wdata_reg;
    
    // AXI4-Lite read FSM
    reg [1:0] read_state, next_read_state;
    localparam R_IDLE = 2'b00;
    localparam R_DATA = 2'b01;
    
    reg [3:0] raddr_reg;
    
    // Write channel FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_state <= W_IDLE;
            waddr_reg <= 4'h0;
            wdata_reg <= 32'h0;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= RESP_OKAY;
        end else begin
            case (write_state)
                W_IDLE: begin
                    s_axil_bvalid <= 1'b0;
                    if (s_axil_awvalid) begin
                        s_axil_awready <= 1'b1;
                        waddr_reg <= s_axil_awaddr[5:2]; // 4-byte aligned addresses
                        write_state <= W_DATA;
                    end else begin
                        s_axil_awready <= 1'b0;
                    end
                end
                
                W_DATA: begin
                    s_axil_awready <= 1'b0;
                    if (s_axil_wvalid) begin
                        s_axil_wready <= 1'b1;
                        wdata_reg <= s_axil_wdata;
                        write_state <= W_RESP;
                        
                        // Register write operations
                        case (waddr_reg)
                            ADDR_TX_REQUEST: tx_request <= s_axil_wdata[0];
                            ADDR_TX_COMPLETE: tx_complete <= s_axil_wdata[0];
                            ADDR_PAUSE_FRAME_RX: pause_frame_rx <= s_axil_wdata[0];
                            ADDR_PAUSE_QUANTA_RX: pause_quanta_rx <= s_axil_wdata[15:0];
                            ADDR_BUFFER_STATUS: rx_buffer_almost_full <= s_axil_wdata[0];
                            default: begin
                                // Read-only registers or invalid addresses
                                if (waddr_reg >= ADDR_TX_GRANT && waddr_reg <= ADDR_FLOW_CTRL_STAT) begin
                                    // These are read-only registers
                                    s_axil_bresp <= RESP_SLVERR;
                                end else begin
                                    s_axil_bresp <= RESP_OKAY;
                                end
                            end
                        endcase
                    end else begin
                        s_axil_wready <= 1'b0;
                    end
                end
                
                W_RESP: begin
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b1;
                    
                    if (s_axil_bready) begin
                        write_state <= W_IDLE;
                        s_axil_bvalid <= 1'b0;
                    end
                end
                
                default: write_state <= W_IDLE;
            endcase
        end
    end
    
    // Read channel FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_state <= R_IDLE;
            raddr_reg <= 4'h0;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= RESP_OKAY;
        end else begin
            case (read_state)
                R_IDLE: begin
                    if (s_axil_arvalid) begin
                        s_axil_arready <= 1'b1;
                        raddr_reg <= s_axil_araddr[5:2]; // 4-byte aligned addresses
                        read_state <= R_DATA;
                    end else begin
                        s_axil_arready <= 1'b0;
                    end
                end
                
                R_DATA: begin
                    s_axil_arready <= 1'b0;
                    s_axil_rvalid <= 1'b1;
                    
                    // Register read operations
                    case (raddr_reg)
                        ADDR_TX_REQUEST: s_axil_rdata <= {31'b0, tx_request};
                        ADDR_TX_COMPLETE: s_axil_rdata <= {31'b0, tx_complete};
                        ADDR_PAUSE_FRAME_RX: s_axil_rdata <= {31'b0, pause_frame_rx};
                        ADDR_PAUSE_QUANTA_RX: s_axil_rdata <= {16'b0, pause_quanta_rx};
                        ADDR_BUFFER_STATUS: s_axil_rdata <= {31'b0, rx_buffer_almost_full};
                        ADDR_TX_GRANT: s_axil_rdata <= {31'b0, tx_grant};
                        ADDR_RX_ENABLE: s_axil_rdata <= {31'b0, rx_enable};
                        ADDR_PAUSE_FRAME_TX: s_axil_rdata <= {31'b0, pause_frame_tx};
                        ADDR_PAUSE_QUANTA_TX: s_axil_rdata <= {16'b0, pause_quanta_tx};
                        ADDR_FLOW_CTRL_STAT: s_axil_rdata <= {31'b0, flow_control_active};
                        default: begin
                            s_axil_rdata <= 32'h0;
                            s_axil_rresp <= RESP_SLVERR;
                        end
                    endcase
                    
                    if (s_axil_rready) begin
                        read_state <= R_IDLE;
                        s_axil_rvalid <= 1'b0;
                        s_axil_rresp <= RESP_OKAY;
                    end
                end
                
                default: read_state <= R_IDLE;
            endcase
        end
    end
    
    // Sequential logic for core functionality
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            pause_counter <= 16'd0;
            ifg_counter <= 4'd0;
            tx_grant <= 1'b0;
            rx_enable <= 1'b1; // Always enabled in full-duplex
            pause_frame_tx <= 1'b0;
            pause_quanta_tx <= 16'd0;
            flow_control_active <= 1'b0;
        end else begin
            state <= next_state;
            pause_counter <= next_pause_counter;
            ifg_counter <= next_ifg_counter;
            
            // Generate pause frames based on buffer status
            if (rx_buffer_almost_full && !pause_frame_tx) begin
                pause_frame_tx <= 1'b1;
                pause_quanta_tx <= 16'hFFFF; // Request max pause
            end else if (!rx_buffer_almost_full) begin
                pause_frame_tx <= 1'b0;
            end
        end
    end
    
    // Combinational logic - optimized state and counter updates
    always @(*) begin
        // Default assignments to prevent latches
        next_state = state;
        next_pause_counter = pause_counter;
        next_ifg_counter = ifg_counter;
        
        // Handle received pause frames with priority logic
        if (pause_frame_rx && |pause_quanta_rx) begin  // Optimized non-zero check
            next_pause_counter = pause_quanta_rx;
            flow_control_active = 1'b1;
            
            case (state)
                TRANSMIT: next_state = PAUSE;
                IDLE: begin
                    next_state = PAUSE;
                    tx_grant = 1'b0;
                end
                default: ; // No change
            endcase
        end else begin
            // State machine with optimized comparisons
            case (state)
                IDLE: begin
                    tx_grant = 1'b0;
                    if (tx_request && !flow_control_active) begin
                        tx_grant = 1'b1;
                        next_state = TRANSMIT;
                    end
                end
                
                TRANSMIT: begin
                    tx_grant = 1'b1;
                    if (tx_complete) begin
                        tx_grant = 1'b0;
                        next_state = WAIT_IFG;
                        next_ifg_counter = IFG_TIME;
                    end
                end
                
                PAUSE: begin
                    tx_grant = 1'b0;
                    if (|pause_counter) begin  // Optimized non-zero check
                        next_pause_counter = pause_counter - 1'b1;
                    end else begin
                        flow_control_active = 1'b0;
                        next_state = IDLE;
                    end
                end
                
                WAIT_IFG: begin
                    tx_grant = 1'b0;
                    if (|ifg_counter) begin  // Optimized non-zero check
                        next_ifg_counter = ifg_counter - 1'b1;
                    end else begin
                        next_state = IDLE;
                    end
                end
                
                default: next_state = IDLE;
            endcase
        end
    end
endmodule