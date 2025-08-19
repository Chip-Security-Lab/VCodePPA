module eth_rmii_interface (
    // Clock and reset
    input wire ref_clk, // 50MHz reference clock
    input wire rst_n,
    
    // MAC side interface
    input wire [7:0] mac_tx_data,
    input wire mac_tx_en,
    output reg [7:0] mac_rx_data,
    output reg mac_rx_dv,
    output reg mac_rx_er,
    
    // RMII side interface
    output reg [1:0] rmii_txd,
    output reg rmii_tx_en,
    input wire [1:0] rmii_rxd,
    input wire rmii_crs_dv
);
    // RX state machine
    reg rx_state;
    reg [1:0] rmii_rxd_r;
    reg rmii_crs_dv_r;
    
    // TX nibble counter
    reg tx_nibble;
    
    // RMII is 2 bits at a time @ 50MHz = MII 4 bits @ 25MHz
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            mac_rx_data <= 8'h00;
            mac_rx_dv <= 1'b0;
            mac_rx_er <= 1'b0;
            rx_state <= 1'b0;
            rmii_rxd_r <= 2'b00;
            rmii_crs_dv_r <= 1'b0;
        end else begin
            // Register inputs for timing
            rmii_rxd_r <= rmii_rxd;
            rmii_crs_dv_r <= rmii_crs_dv;
            
            // RX processing (2-bit to 8-bit)
            if (rmii_crs_dv_r) begin
                if (rx_state == 1'b0) begin
                    // First 2 bits of nibble
                    mac_rx_data[1:0] <= rmii_rxd_r;
                    rx_state <= 1'b1;
                end else begin
                    // Second 2 bits of nibble
                    mac_rx_data[3:2] <= rmii_rxd_r;
                    // Wait for low nibble now
                    rx_state <= 1'b0;
                end
            end else begin
                mac_rx_dv <= 1'b0;
                rx_state <= 1'b0;
            end
            
            // On completion of low nibble, signal valid data
            if (rx_state == 1'b0 && rmii_crs_dv_r) begin
                mac_rx_dv <= 1'b1;
            end
        end
    end
    
    // Transmit processing (8-bit to 2-bit)
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            rmii_txd <= 2'b00;
            rmii_tx_en <= 1'b0;
            tx_nibble <= 1'b0;
        end else begin
            rmii_tx_en <= mac_tx_en;
            
            if (mac_tx_en) begin
                if (tx_nibble == 1'b0) begin
                    // First 2 bits of high nibble
                    rmii_txd <= mac_tx_data[1:0];
                    tx_nibble <= 1'b1;
                end else begin
                    // Second 2 bits of high nibble
                    rmii_txd <= mac_tx_data[3:2];
                    tx_nibble <= 1'b0;
                end
            end else begin
                tx_nibble <= 1'b0;
                rmii_txd <= 2'b00;
            end
        end
    end
endmodule