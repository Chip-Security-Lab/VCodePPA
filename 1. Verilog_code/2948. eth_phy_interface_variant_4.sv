//SystemVerilog
module eth_phy_interface (
    input wire clk_tx,
    input wire clk_rx,
    input wire reset,
    // MAC layer interface
    input wire [7:0] mac_tx_data,
    input wire mac_tx_valid,
    output reg mac_tx_ready,
    output reg [7:0] mac_rx_data,
    output reg mac_rx_valid,
    output reg mac_rx_error,
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
    // Restructured input buffering with buffer stages
    reg [7:0] mac_tx_data_reg;
    // Fanout buffering for mac_tx_data_reg
    reg [7:0] mac_tx_data_buf1, mac_tx_data_buf2;
    
    reg mac_tx_valid_reg;
    reg [3:0] phy_rxd_reg;
    // Fanout buffering for phy_rxd_reg
    reg [3:0] phy_rxd_buf1, phy_rxd_buf2;
    
    reg phy_rx_dv_reg;
    reg phy_rx_er_reg;
    
    // Transmit state machine
    reg [1:0] tx_state, next_tx_state;
    // Buffered next_tx_state to reduce fanout
    reg [1:0] next_tx_state_buf1, next_tx_state_buf2;
    
    localparam TX_IDLE = 2'b00, TX_DATA = 2'b01, TX_LAST = 2'b10;
    
    // Buffered TX_IDLE constant to reduce high fanout references
    reg [1:0] tx_idle_buf1, tx_idle_buf2;
    
    // TX state logic - optimized state encoding
    reg [2:0] tx_state_onehot; // One-hot encoding for state-dependent actions
    
    // Balanced load distribution for common signals
    reg b0; // Base boolean signal
    reg b0_buf1, b0_buf2, b0_buf3; // Buffered copies for different parts of logic
    
    // Initialize buffered constants
    initial begin
        tx_idle_buf1 = TX_IDLE;
        tx_idle_buf2 = TX_IDLE;
    end
    
    // Pre-compute next state logic in combinational domain
    always @(*) begin
        next_tx_state = tx_state;
        case (tx_state)
            TX_IDLE: if (mac_tx_valid_reg) next_tx_state = TX_DATA;
            TX_DATA: next_tx_state = TX_LAST;
            TX_LAST: begin
                if (mac_tx_valid_reg) next_tx_state = TX_DATA;
                else next_tx_state = TX_IDLE;
            end
            default: next_tx_state = TX_IDLE;
        endcase
    end
    
    // Register inputs after first-level combinatorial logic
    always @(posedge clk_tx) begin
        mac_tx_data_reg <= mac_tx_data;
        mac_tx_valid_reg <= mac_tx_valid;
        
        // Buffer high fanout signals
        next_tx_state_buf1 <= next_tx_state;
        next_tx_state_buf2 <= next_tx_state;
        
        // Buffer data for different consumers
        mac_tx_data_buf1 <= mac_tx_data_reg;
        mac_tx_data_buf2 <= mac_tx_data_reg;
        
        // Base boolean for reuse
        b0 <= (tx_state == TX_IDLE);
        b0_buf1 <= b0;
        b0_buf2 <= b0;
        b0_buf3 <= b0;
    end
    
    always @(posedge clk_rx) begin
        phy_rxd_reg <= phy_rxd;
        phy_rx_dv_reg <= phy_rx_dv;
        phy_rx_er_reg <= phy_rx_er;
        
        // Buffer high fanout signals
        phy_rxd_buf1 <= phy_rxd_reg;
        phy_rxd_buf2 <= phy_rxd_reg;
    end
    
    // Transmit logic with optimized register placement
    always @(posedge clk_tx or posedge reset) begin
        if (reset) begin
            tx_state <= TX_IDLE;
            phy_txd <= 4'h0;
            phy_tx_en <= 1'b0;
            phy_tx_er <= 1'b0;
            mac_tx_ready <= 1'b1;
            tx_state_onehot <= 3'b001; // One-hot for TX_IDLE
        end else begin
            tx_state <= next_tx_state_buf1; // Use buffered next state
            
            // One-hot encoding for critical state transitions to reduce fan-out
            tx_state_onehot <= (next_tx_state_buf2 == tx_idle_buf1) ? 3'b001 :
                               (next_tx_state_buf2 == TX_DATA) ? 3'b010 : 
                               (next_tx_state_buf2 == TX_LAST) ? 3'b100 : 3'b000;
            
            case (tx_state)
                TX_IDLE: begin
                    if (mac_tx_valid_reg) begin
                        phy_txd <= mac_tx_data_buf1[3:0];
                        phy_tx_en <= 1'b1;
                        mac_tx_ready <= 1'b0;
                    end else begin
                        phy_tx_en <= 1'b0;
                        mac_tx_ready <= 1'b1;
                    end
                end
                
                TX_DATA: begin
                    phy_txd <= mac_tx_data_buf2[7:4];
                end
                
                TX_LAST: begin
                    if (mac_tx_valid_reg) begin
                        phy_txd <= mac_tx_data_buf1[3:0];
                    end else begin
                        phy_tx_en <= 1'b0;
                        mac_tx_ready <= 1'b1;
                    end
                end
                
                default: begin
                    // Default state assignments
                    phy_tx_en <= 1'b0;
                    mac_tx_ready <= 1'b1;
                end
            endcase
        end
    end
    
    // Receive state machine with retimed registers
    reg [1:0] rx_state, next_rx_state;
    reg [3:0] rx_nibble;
    localparam RX_IDLE = 2'b00, RX_FIRST = 2'b01, RX_SECOND = 2'b10;
    
    // Pre-compute next state logic to balance delays
    always @(*) begin
        next_rx_state = rx_state;
        case (rx_state)
            RX_IDLE: if (phy_rx_dv_reg) next_rx_state = RX_SECOND;
            RX_FIRST: begin
                if (phy_rx_dv_reg) next_rx_state = RX_SECOND;
                else next_rx_state = RX_IDLE;
            end
            RX_SECOND: begin
                if (phy_rx_dv_reg) next_rx_state = RX_FIRST;
                else next_rx_state = RX_IDLE;
            end
            default: next_rx_state = RX_IDLE;
        endcase
    end
    
    // Receive logic with retimed registers
    always @(posedge clk_rx or posedge reset) begin
        if (reset) begin
            rx_state <= RX_IDLE;
            mac_rx_data <= 8'h00;
            mac_rx_valid <= 1'b0;
            mac_rx_error <= 1'b0;
            rx_nibble <= 4'h0;
        end else begin
            rx_state <= next_rx_state;
            
            // Default assignment
            mac_rx_valid <= 1'b0;
            mac_rx_error <= phy_rx_er_reg;
            
            case (rx_state)
                RX_IDLE: begin
                    if (phy_rx_dv_reg) begin
                        rx_nibble <= phy_rxd_buf1;
                    end
                end
                
                RX_FIRST: begin
                    if (phy_rx_dv_reg) begin
                        rx_nibble <= phy_rxd_buf1;
                    end
                end
                
                RX_SECOND: begin
                    if (phy_rx_dv_reg) begin
                        mac_rx_data <= {phy_rxd_buf2, rx_nibble};
                        mac_rx_valid <= 1'b1;
                    end
                end
                
                default: begin
                    // No operation
                end
            endcase
        end
    end
endmodule