//SystemVerilog
module eth_phy_interface (
    // Global signals
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [7:0] s_axi_awaddr,
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
    input wire [7:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // PHY layer interface
    output reg [3:0] phy_txd,
    output reg phy_tx_en,
    output reg phy_tx_er,
    input wire [3:0] phy_rxd,
    input wire phy_rx_dv,
    input wire phy_rx_er,
    input wire phy_crs,
    input wire phy_col
);

    // AXI4-Lite Register Addresses
    localparam [7:0] REG_CTRL         = 8'h00,  // Control register
                     REG_STATUS       = 8'h04,  // Status register
                     REG_TX_DATA      = 8'h08,  // Transmit data
                     REG_RX_DATA      = 8'h0C;  // Receive data

    // Control/Status Register bits
    localparam TX_START_BIT = 0,    // Control reg bit to start transmission
               TX_READY_BIT = 0,    // Status reg bit showing tx ready
               RX_VALID_BIT = 1,    // Status reg bit showing rx valid
               RX_ERROR_BIT = 2;    // Status reg bit showing rx error

    // Internal registers
    reg [31:0] ctrl_reg;
    reg [31:0] status_reg;
    reg [7:0] tx_data_reg;
    reg [7:0] rx_data_reg;
    
    // TX control signals
    reg tx_start;
    wire tx_ready;
    
    // RX status signals
    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_error;
    
    // AXI4-Lite FSM states
    localparam [1:0] IDLE = 2'b00,
                     WADDR = 2'b01,
                     WDATA = 2'b10,
                     WRESP = 2'b11;
                     
    localparam [1:0] RADDR = 2'b01,
                     RDATA = 2'b10;
                   
    reg [1:0] write_state;
    reg [1:0] read_state;
    reg [7:0] axi_awaddr_reg;
    reg [7:0] axi_araddr_reg;
    
    // Transmit state machine
    reg [2:0] tx_state;
    localparam TX_IDLE = 3'b000, TX_DATA_PREP = 3'b001, TX_DATA_1 = 3'b010, 
               TX_DATA_2 = 3'b011, TX_LAST_PREP = 3'b100, TX_LAST = 3'b101;
    
    // Pipeline registers for transmit path
    reg [7:0] tx_data_stage1, tx_data_stage2;
    reg tx_valid_stage1, tx_valid_stage2;
    reg [3:0] phy_txd_next;
    reg phy_tx_en_next;
    
    // Receive state machine
    reg [2:0] rx_state;
    reg [3:0] rx_nibble_stage1, rx_nibble_stage2;
    reg rx_dv_stage1, rx_dv_stage2;
    reg rx_er_stage1, rx_er_stage2;
    reg [7:0] rx_data_next;
    reg rx_valid_next;
    reg rx_error_next;
    
    localparam RX_IDLE = 3'b000, RX_CAPTURE = 3'b001, RX_FIRST_PROC = 3'b010, 
               RX_SECOND_PREP = 3'b011, RX_SECOND = 3'b100, RX_OUTPUT = 3'b101;
    
    // AXI4-Lite Write transaction
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            axi_awaddr_reg <= 8'h0;
            
            ctrl_reg <= 32'h0;
            tx_data_reg <= 8'h0;
            tx_start <= 1'b0;
        end else begin
            // Default behavior
            tx_start <= 1'b0;  // One-cycle pulse
            
            case (write_state)
                IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready <= 1'b0;
                    if (s_axi_awvalid && s_axi_awready) begin
                        axi_awaddr_reg <= s_axi_awaddr;
                        s_axi_awready <= 1'b0;
                        s_axi_wready <= 1'b1;
                        write_state <= WDATA;
                    end
                end
                
                WDATA: begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        s_axi_wready <= 1'b0;
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp <= 2'b00;  // OKAY response
                        
                        case (axi_awaddr_reg)
                            REG_CTRL: begin
                                if (s_axi_wstrb[0]) begin
                                    ctrl_reg[7:0] <= s_axi_wdata[7:0];
                                    if (s_axi_wdata[TX_START_BIT] && tx_ready)
                                        tx_start <= 1'b1;
                                end
                                if (s_axi_wstrb[1]) ctrl_reg[15:8] <= s_axi_wdata[15:8];
                                if (s_axi_wstrb[2]) ctrl_reg[23:16] <= s_axi_wdata[23:16];
                                if (s_axi_wstrb[3]) ctrl_reg[31:24] <= s_axi_wdata[31:24];
                            end
                            
                            REG_TX_DATA: begin
                                if (s_axi_wstrb[0]) tx_data_reg <= s_axi_wdata[7:0];
                            end
                            
                            default: begin
                                // No action for invalid addresses
                            end
                        endcase
                        
                        write_state <= WRESP;
                    end
                end
                
                WRESP: begin
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
    
    // AXI4-Lite Read transaction
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= IDLE;
            s_axi_arready <= 1'b1;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            s_axi_rdata <= 32'h0;
            axi_araddr_reg <= 8'h0;
        end else begin
            case (read_state)
                IDLE: begin
                    s_axi_arready <= 1'b1;
                    if (s_axi_arvalid && s_axi_arready) begin
                        axi_araddr_reg <= s_axi_araddr;
                        s_axi_arready <= 1'b0;
                        read_state <= RDATA;
                    end
                end
                
                RDATA: begin
                    s_axi_rvalid <= 1'b1;
                    s_axi_rresp <= 2'b00;  // OKAY response
                    
                    case (axi_araddr_reg)
                        REG_CTRL: begin
                            s_axi_rdata <= ctrl_reg;
                        end
                        
                        REG_STATUS: begin
                            s_axi_rdata <= {29'h0, rx_error, rx_valid, tx_ready};
                        end
                        
                        REG_TX_DATA: begin
                            s_axi_rdata <= {24'h0, tx_data_reg};
                        end
                        
                        REG_RX_DATA: begin
                            s_axi_rdata <= {24'h0, rx_data};
                        end
                        
                        default: begin
                            s_axi_rdata <= 32'h0;
                        end
                    endcase
                    
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
    
    // Transmit logic with deeper pipeline
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            tx_state <= TX_IDLE;
            phy_txd <= 4'h0;
            phy_tx_en <= 1'b0;
            phy_tx_er <= 1'b0;
            tx_data_stage1 <= 8'h0;
            tx_data_stage2 <= 8'h0;
            tx_valid_stage1 <= 1'b0;
            tx_valid_stage2 <= 1'b0;
            phy_txd_next <= 4'h0;
            phy_tx_en_next <= 1'b0;
        end else begin
            // Pipeline stage register updates
            tx_data_stage1 <= tx_data_reg;
            tx_data_stage2 <= tx_data_stage1;
            tx_valid_stage1 <= tx_start;
            tx_valid_stage2 <= tx_valid_stage1;
            
            // Output register updates
            phy_txd <= phy_txd_next;
            phy_tx_en <= phy_tx_en_next;
            
            case (tx_state)
                TX_IDLE: begin
                    if (tx_start) begin
                        tx_state <= TX_DATA_PREP;
                    end else begin
                        phy_tx_en_next <= 1'b0;
                    end
                end
                
                TX_DATA_PREP: begin
                    tx_state <= TX_DATA_1;
                    phy_tx_en_next <= 1'b1;
                end
                
                TX_DATA_1: begin
                    phy_txd_next <= tx_data_stage2[3:0];
                    tx_state <= TX_DATA_2;
                end
                
                TX_DATA_2: begin
                    phy_txd_next <= tx_data_stage2[7:4];
                    tx_state <= TX_LAST_PREP;
                end
                
                TX_LAST_PREP: begin
                    tx_state <= TX_LAST;
                end
                
                TX_LAST: begin
                    if (tx_valid_stage2) begin
                        phy_txd_next <= tx_data_stage2[3:0];
                        tx_state <= TX_DATA_1;
                    end else begin
                        phy_tx_en_next <= 1'b0;
                        tx_state <= TX_IDLE;
                    end
                end
                
                default: tx_state <= TX_IDLE;
            endcase
        end
    end
    
    // Receive logic with deeper pipeline
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rx_state <= RX_IDLE;
            rx_data_reg <= 8'h00;
            rx_valid_next <= 1'b0;
            rx_error_next <= 1'b0;
            rx_nibble_stage1 <= 4'h0;
            rx_nibble_stage2 <= 4'h0;
            rx_dv_stage1 <= 1'b0;
            rx_dv_stage2 <= 1'b0;
            rx_er_stage1 <= 1'b0;
            rx_er_stage2 <= 1'b0;
            rx_data_next <= 8'h00;
        end else begin
            // Pipeline input register updates
            rx_nibble_stage1 <= phy_rxd;
            rx_nibble_stage2 <= rx_nibble_stage1;
            rx_dv_stage1 <= phy_rx_dv;
            rx_dv_stage2 <= rx_dv_stage1;
            rx_er_stage1 <= phy_rx_er;
            rx_er_stage2 <= rx_er_stage1;
            
            // Default next-state assignments
            rx_valid_next <= 1'b0;
            rx_error_next <= rx_er_stage2;
            
            case (rx_state)
                RX_IDLE: begin
                    if (phy_rx_dv) begin
                        rx_state <= RX_CAPTURE;
                    end
                end
                
                RX_CAPTURE: begin
                    rx_state <= RX_FIRST_PROC;
                end
                
                RX_FIRST_PROC: begin
                    if (rx_dv_stage2) begin
                        rx_state <= RX_SECOND_PREP;
                    end else begin
                        rx_state <= RX_IDLE;
                    end
                end
                
                RX_SECOND_PREP: begin
                    rx_state <= RX_SECOND;
                end
                
                RX_SECOND: begin
                    if (rx_dv_stage2) begin
                        rx_data_next <= {rx_nibble_stage2, rx_nibble_stage1};
                        rx_data_reg <= {rx_nibble_stage2, rx_nibble_stage1};
                        rx_valid_next <= 1'b1;
                        rx_state <= RX_OUTPUT;
                    end else begin
                        rx_state <= RX_IDLE;
                    end
                end
                
                RX_OUTPUT: begin
                    rx_state <= RX_FIRST_PROC;
                end
                
                default: rx_state <= RX_IDLE;
            endcase
        end
    end
    
    // Status signals for AXI registers
    assign tx_ready = (tx_state == TX_IDLE);
    assign rx_valid = rx_valid_next;
    assign rx_error = rx_error_next;
    assign rx_data = rx_data_reg;
    
    // Status register (updated continuously)
    always @(*) begin
        status_reg = {29'h0, rx_error, rx_valid, tx_ready};
    end

endmodule