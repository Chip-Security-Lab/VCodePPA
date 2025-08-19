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
    // Constants pre-defined to avoid repetitive logic
    localparam TX_IDLE = 2'b00;
    localparam TX_DATA = 2'b01;
    localparam TX_LAST = 2'b10;
    localparam RX_IDLE = 2'b00;
    localparam RX_FIRST = 2'b01;
    localparam RX_SECOND = 2'b10;
    
    // Transmit state machine
    reg [1:0] tx_state;
    reg [1:0] next_tx_state; // Pre-compute next state
    
    // Pipeline registers for tx data path
    reg [7:0] mac_tx_data_p1;
    reg [3:0] phy_txd_next;
    reg phy_tx_en_next;
    reg mac_tx_ready_next;
    
    // Buffer high fanout signals once only
    wire b0 = 1'b0;
    wire b1 = 1'b1;
    
    // Receive state machine
    reg [1:0] rx_state;
    reg [1:0] next_rx_state; // Pre-compute next state
    reg [3:0] rx_nibble;
    
    // Pipeline registers for rx data path
    reg [3:0] phy_rxd_p1;
    reg phy_rx_dv_p1;
    reg phy_rx_er_p1;
    
    // Buffer rx inputs to reduce load and improve timing
    always @(posedge clk_rx) begin
        phy_rxd_p1 <= phy_rxd;
        phy_rx_dv_p1 <= phy_rx_dv;
        phy_rx_er_p1 <= phy_rx_er;
    end
    
    // Buffer tx inputs
    always @(posedge clk_tx) begin
        mac_tx_data_p1 <= mac_tx_data;
    end
    
    // Pre-compute tx next state logic to break critical path
    always @(*) begin
        next_tx_state = tx_state;
        phy_txd_next = phy_txd;
        phy_tx_en_next = phy_tx_en;
        mac_tx_ready_next = mac_tx_ready;
        
        case (tx_state)
            TX_IDLE: begin
                if (mac_tx_valid) begin
                    phy_txd_next = mac_tx_data_p1[3:0];
                    phy_tx_en_next = b1;
                    next_tx_state = TX_DATA;
                    mac_tx_ready_next = b0;
                end else begin
                    phy_tx_en_next = b0;
                    mac_tx_ready_next = b1;
                end
            end
            
            TX_DATA: begin
                phy_txd_next = mac_tx_data_p1[7:4];
                next_tx_state = TX_LAST;
            end
            
            TX_LAST: begin
                if (mac_tx_valid) begin
                    phy_txd_next = mac_tx_data_p1[3:0];
                    next_tx_state = TX_DATA;
                end else begin
                    phy_tx_en_next = b0;
                    next_tx_state = TX_IDLE;
                    mac_tx_ready_next = b1;
                end
            end
            
            default: next_tx_state = TX_IDLE;
        endcase
    end
    
    // Apply next state and outputs in register update
    always @(posedge clk_tx or posedge reset) begin
        if (reset) begin
            tx_state <= TX_IDLE;
            phy_txd <= 4'h0;
            phy_tx_en <= b0;
            phy_tx_er <= b0;
            mac_tx_ready <= b1;
        end else begin
            tx_state <= next_tx_state;
            phy_txd <= phy_txd_next;
            phy_tx_en <= phy_tx_en_next;
            mac_tx_ready <= mac_tx_ready_next;
        end
    end
    
    // Pre-compute rx next state logic
    always @(*) begin
        next_rx_state = rx_state;
        
        case (rx_state)
            RX_IDLE: begin
                if (phy_rx_dv_p1) begin
                    next_rx_state = RX_SECOND;
                end
            end
            
            RX_FIRST: begin
                if (phy_rx_dv_p1) begin
                    next_rx_state = RX_SECOND;
                end else begin
                    next_rx_state = RX_IDLE;
                end
            end
            
            RX_SECOND: begin
                if (phy_rx_dv_p1) begin
                    next_rx_state = RX_FIRST;
                end else begin
                    next_rx_state = RX_IDLE;
                end
            end
            
            default: next_rx_state = RX_IDLE;
        endcase
    end
    
    // Receive logic with balanced paths
    always @(posedge clk_rx or posedge reset) begin
        if (reset) begin
            rx_state <= RX_IDLE;
            mac_rx_data <= 8'h00;
            mac_rx_valid <= 1'b0;
            mac_rx_error <= 1'b0;
            rx_nibble <= 4'h0;
        end else begin
            // Default assignments
            mac_rx_valid <= 1'b0;
            mac_rx_error <= phy_rx_er_p1;
            rx_state <= next_rx_state;
            
            // Capture first nibble in both RX_IDLE and RX_FIRST states
            if ((rx_state == RX_IDLE || rx_state == RX_FIRST) && phy_rx_dv_p1) begin
                rx_nibble <= phy_rxd_p1;
            end
            
            // Output data in RX_SECOND state
            if (rx_state == RX_SECOND && phy_rx_dv_p1) begin
                mac_rx_data <= {phy_rxd_p1, rx_nibble};
                mac_rx_valid <= 1'b1;
            end
        end
    end
endmodule