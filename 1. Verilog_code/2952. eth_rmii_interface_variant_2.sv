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
    // RX state machine
    reg rx_state;
    reg [1:0] rmii_rxd_r;
    reg rmii_crs_dv_r;
    
    // TX nibble counter
    reg tx_nibble;
    
    // Register inputs for timing
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            rmii_rxd_r <= 2'b00;
            rmii_crs_dv_r <= 1'b0;
        end else begin
            rmii_rxd_r <= rmii_rxd;
            rmii_crs_dv_r <= rmii_crs_dv;
        end
    end
    
    // RX state control
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state <= 1'b0;
        end else begin
            case (rmii_crs_dv_r)
                1'b1: rx_state <= ~rx_state;
                1'b0: rx_state <= 1'b0;
            endcase
        end
    end
    
    // RX data processing
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            mac_rx_data <= 8'h00;
        end else if (rmii_crs_dv_r) begin
            case (rx_state)
                1'b0: mac_rx_data[1:0] <= rmii_rxd_r;
                1'b1: mac_rx_data[3:2] <= rmii_rxd_r;
            endcase
        end
    end
    
    // RX data valid control
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            mac_rx_dv <= 1'b0;
        end else begin
            case ({rx_state, rmii_crs_dv_r})
                2'b01: mac_rx_dv <= 1'b1; // rx_state=0, crs_dv=1
                2'b00, 2'b10: mac_rx_dv <= 1'b0; // crs_dv=0
                2'b11: mac_rx_dv <= mac_rx_dv; // Keep previous value
            endcase
        end
    end
    
    // RX error handling
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            mac_rx_er <= 1'b0;
        end else begin
            mac_rx_er <= 1'b0; // Error handling logic can be added here if needed
        end
    end
    
    // TX enable control
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            rmii_tx_en <= 1'b0;
        end else begin
            rmii_tx_en <= mac_tx_en;
        end
    end
    
    // TX nibble state control
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_nibble <= 1'b0;
        end else begin
            case (mac_tx_en)
                1'b1: tx_nibble <= ~tx_nibble;
                1'b0: tx_nibble <= 1'b0;
            endcase
        end
    end
    
    // TX data output
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            rmii_txd <= 2'b00;
        end else begin
            case ({mac_tx_en, tx_nibble})
                2'b10: rmii_txd <= mac_tx_data[1:0]; // mac_tx_en=1, tx_nibble=0
                2'b11: rmii_txd <= mac_tx_data[3:2]; // mac_tx_en=1, tx_nibble=1
                2'b00, 2'b01: rmii_txd <= 2'b00;    // mac_tx_en=0
            endcase
        end
    end
    
endmodule