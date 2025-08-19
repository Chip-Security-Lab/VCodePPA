//SystemVerilog
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
    // Pre-registered inputs to break timing paths
    reg [7:0] mac_tx_data_r;
    reg mac_tx_en_r;
    
    // Intermediate signals to improve timing
    reg [1:0] rmii_rxd_r, rmii_rxd_r2;
    reg rmii_crs_dv_r, rmii_crs_dv_r2;
    
    // State machines and counters
    reg rx_state;
    reg tx_nibble;
    reg [3:0] rx_data_low;
    
    // Input registration - forward retiming
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            rmii_rxd_r <= 2'b00;
            rmii_crs_dv_r <= 1'b0;
            mac_tx_data_r <= 8'h00;
            mac_tx_en_r <= 1'b0;
        end else begin
            // Register inputs immediately to improve timing
            rmii_rxd_r <= rmii_rxd;
            rmii_crs_dv_r <= rmii_crs_dv;
            mac_tx_data_r <= mac_tx_data;
            mac_tx_en_r <= mac_tx_en;
        end
    end
    
    // Second stage registration for RX path - breaking critical paths
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            rmii_rxd_r2 <= 2'b00;
            rmii_crs_dv_r2 <= 1'b0;
        end else begin
            rmii_rxd_r2 <= rmii_rxd_r;
            rmii_crs_dv_r2 <= rmii_crs_dv_r;
        end
    end
    
    // RX processing with improved timing (2-bit to 8-bit)
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            mac_rx_data <= 8'h00;
            mac_rx_dv <= 1'b0;
            mac_rx_er <= 1'b0;
            rx_state <= 1'b0;
            rx_data_low <= 4'h0;
        end else begin
            if (rmii_crs_dv_r2) begin
                if (rx_state == 1'b0) begin
                    // Store first 2 bits
                    rx_data_low[1:0] <= rmii_rxd_r2;
                    rx_state <= 1'b1;
                    mac_rx_dv <= 1'b0; // Hold off DV until we have full byte
                end else begin
                    // Second 2 bits complete the nibble
                    rx_data_low[3:2] <= rmii_rxd_r2;
                    // Completed a byte, signal valid data
                    mac_rx_data <= {4'h0, rx_data_low[1:0], rmii_rxd_r2};
                    mac_rx_dv <= 1'b1;
                    rx_state <= 1'b0;
                end
            end else begin
                mac_rx_dv <= 1'b0;
                rx_state <= 1'b0;
                mac_rx_er <= 1'b0;
            end
        end
    end
    
    // Transmit processing with improved timing (8-bit to 2-bit)
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            rmii_txd <= 2'b00;
            rmii_tx_en <= 1'b0;
            tx_nibble <= 1'b0;
        end else begin
            rmii_tx_en <= mac_tx_en_r;
            
            if (mac_tx_en_r) begin
                if (tx_nibble == 1'b0) begin
                    // First 2 bits of nibble
                    rmii_txd <= mac_tx_data_r[1:0];
                    tx_nibble <= 1'b1;
                end else begin
                    // Second 2 bits of nibble
                    rmii_txd <= mac_tx_data_r[3:2];
                    tx_nibble <= 1'b0;
                end
            end else begin
                tx_nibble <= 1'b0;
                rmii_txd <= 2'b00;
            end
        end
    end
endmodule