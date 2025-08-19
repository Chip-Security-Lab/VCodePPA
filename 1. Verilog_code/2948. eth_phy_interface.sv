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
    // Transmit state machine
    reg [1:0] tx_state;
    localparam TX_IDLE = 2'b00, TX_DATA = 2'b01, TX_LAST = 2'b10;
    
    // Transmit logic
    always @(posedge clk_tx or posedge reset) begin
        if (reset) begin
            tx_state <= TX_IDLE;
            phy_txd <= 4'h0;
            phy_tx_en <= 1'b0;
            phy_tx_er <= 1'b0;
            mac_tx_ready <= 1'b1;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    if (mac_tx_valid) begin
                        phy_txd <= mac_tx_data[3:0];
                        phy_tx_en <= 1'b1;
                        tx_state <= TX_DATA;
                        mac_tx_ready <= 1'b0;
                    end else begin
                        phy_tx_en <= 1'b0;
                        mac_tx_ready <= 1'b1;
                    end
                end
                
                TX_DATA: begin
                    phy_txd <= mac_tx_data[7:4];
                    tx_state <= TX_LAST;
                end
                
                TX_LAST: begin
                    if (mac_tx_valid) begin
                        phy_txd <= mac_tx_data[3:0];
                        tx_state <= TX_DATA;
                    end else begin
                        phy_tx_en <= 1'b0;
                        tx_state <= TX_IDLE;
                        mac_tx_ready <= 1'b1;
                    end
                end
                
                default: tx_state <= TX_IDLE;
            endcase
        end
    end
    
    // Receive state machine
    reg [1:0] rx_state;
    reg [3:0] rx_nibble;
    localparam RX_IDLE = 2'b00, RX_FIRST = 2'b01, RX_SECOND = 2'b10;
    
    // Receive logic
    always @(posedge clk_rx or posedge reset) begin
        if (reset) begin
            rx_state <= RX_IDLE;
            mac_rx_data <= 8'h00;
            mac_rx_valid <= 1'b0;
            mac_rx_error <= 1'b0;
            rx_nibble <= 4'h0;
        end else begin
            // Default assignment
            mac_rx_valid <= 1'b0;
            mac_rx_error <= phy_rx_er;
            
            case (rx_state)
                RX_IDLE: begin
                    if (phy_rx_dv) begin
                        rx_nibble <= phy_rxd;
                        rx_state <= RX_SECOND;
                    end
                end
                
                RX_FIRST: begin
                    if (phy_rx_dv) begin
                        rx_nibble <= phy_rxd;
                        rx_state <= RX_SECOND;
                    end else begin
                        rx_state <= RX_IDLE;
                    end
                end
                
                RX_SECOND: begin
                    if (phy_rx_dv) begin
                        mac_rx_data <= {phy_rxd, rx_nibble};
                        mac_rx_valid <= 1'b1;
                        rx_state <= RX_FIRST;
                    end else begin
                        rx_state <= RX_IDLE;
                    end
                end
                
                default: rx_state <= RX_IDLE;
            endcase
        end
    end
endmodule