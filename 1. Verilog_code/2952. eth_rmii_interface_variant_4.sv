//SystemVerilog
// Top level module
module eth_rmii_interface (
    // Clock and reset
    input wire ref_clk, // 50MHz reference clock
    input wire rst_n,
    
    // MAC side interface
    input wire [7:0] mac_tx_data,
    input wire mac_tx_en,
    output wire [7:0] mac_rx_data,
    output wire mac_rx_dv,
    output wire mac_rx_er,
    
    // RMII side interface
    output wire [1:0] rmii_txd,
    output wire rmii_tx_en,
    input wire [1:0] rmii_rxd,
    input wire rmii_crs_dv
);
    // Internal connections
    wire [1:0] rmii_rxd_sync;
    wire rmii_crs_dv_sync;

    // Input synchronizer for metastability prevention
    rmii_input_sync sync_unit (
        .ref_clk(ref_clk),
        .rst_n(rst_n),
        .rmii_rxd_in(rmii_rxd),
        .rmii_crs_dv_in(rmii_crs_dv),
        .rmii_rxd_out(rmii_rxd_sync),
        .rmii_crs_dv_out(rmii_crs_dv_sync)
    );

    // Receiver module - converts 2-bit RMII data to 8-bit MAC data
    rmii_rx_converter rx_unit (
        .ref_clk(ref_clk),
        .rst_n(rst_n),
        .rmii_rxd(rmii_rxd_sync),
        .rmii_crs_dv(rmii_crs_dv_sync),
        .mac_rx_data(mac_rx_data),
        .mac_rx_dv(mac_rx_dv),
        .mac_rx_er(mac_rx_er)
    );

    // Transmitter module - converts 8-bit MAC data to 2-bit RMII data
    rmii_tx_converter tx_unit (
        .ref_clk(ref_clk),
        .rst_n(rst_n),
        .mac_tx_data(mac_tx_data),
        .mac_tx_en(mac_tx_en),
        .rmii_txd(rmii_txd),
        .rmii_tx_en(rmii_tx_en)
    );

endmodule

// Input synchronizer to prevent metastability
module rmii_input_sync (
    input wire ref_clk,
    input wire rst_n,
    input wire [1:0] rmii_rxd_in,
    input wire rmii_crs_dv_in,
    output reg [1:0] rmii_rxd_out,
    output reg rmii_crs_dv_out
);
    // Double-flop synchronization for metastability mitigation
    reg [1:0] rmii_rxd_meta;
    reg rmii_crs_dv_meta;

    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers in parallel for balanced loading
            {rmii_rxd_meta, rmii_rxd_out} <= {2'b00, 2'b00};
            {rmii_crs_dv_meta, rmii_crs_dv_out} <= {1'b0, 1'b0};
        end else begin
            // Parallel assignment to reduce critical path
            {rmii_rxd_meta, rmii_crs_dv_meta} <= {rmii_rxd_in, rmii_crs_dv_in};
            {rmii_rxd_out, rmii_crs_dv_out} <= {rmii_rxd_meta, rmii_crs_dv_meta};
        end
    end
endmodule

// RX converter: RMII 2-bit at 50MHz to MAC 8-bit interface
module rmii_rx_converter (
    input wire ref_clk,
    input wire rst_n,
    input wire [1:0] rmii_rxd,
    input wire rmii_crs_dv,
    output reg [7:0] mac_rx_data,
    output reg mac_rx_dv,
    output reg mac_rx_er
);
    // State definitions - one-hot encoding for faster state transitions
    localparam [3:0] STATE_IDLE = 4'b0001;
    localparam [3:0] STATE_LOW_NIBBLE = 4'b0010;
    localparam [3:0] STATE_HIGH_NIBBLE = 4'b0100;
    localparam [3:0] STATE_COMPLETE = 4'b1000;
    
    reg [3:0] rx_state, rx_next_state;
    reg [3:0] rx_buffer; // Buffer for storing 4 bits (nibble)
    reg [3:0] low_nibble_buffer;
    reg prepare_output;
    
    // Separate next state logic from output generation to balance paths
    always @(*) begin
        rx_next_state = rx_state; // Default: stay in current state
        prepare_output = 1'b0;
        
        case (1'b1) // One-hot case statement
            rx_state[0]: begin // STATE_IDLE
                if (rmii_crs_dv) begin
                    rx_next_state = STATE_LOW_NIBBLE;
                end
            end
            
            rx_state[1]: begin // STATE_LOW_NIBBLE
                if (rmii_crs_dv) begin
                    rx_next_state = STATE_HIGH_NIBBLE;
                end else begin
                    rx_next_state = STATE_IDLE;
                end
            end
            
            rx_state[2]: begin // STATE_HIGH_NIBBLE
                if (rmii_crs_dv) begin
                    rx_next_state = STATE_COMPLETE;
                end else begin
                    rx_next_state = STATE_IDLE;
                end
            end
            
            rx_state[3]: begin // STATE_COMPLETE
                prepare_output = rmii_crs_dv;
                rx_next_state = STATE_IDLE;
            end
        endcase
    end

    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            mac_rx_data <= 8'h00;
            mac_rx_dv <= 1'b0;
            mac_rx_er <= 1'b0;
            rx_state <= STATE_IDLE;
            rx_buffer <= 4'h0;
            low_nibble_buffer <= 4'h0;
        end else begin
            rx_state <= rx_next_state;
            mac_rx_dv <= prepare_output;
            
            case (1'b1) // One-hot case statement
                rx_state[0]: begin // STATE_IDLE
                    mac_rx_dv <= 1'b0;
                    if (rmii_crs_dv) begin
                        rx_buffer[1:0] <= rmii_rxd;
                    end
                end
                
                rx_state[1]: begin // STATE_LOW_NIBBLE
                    if (rmii_crs_dv) begin
                        rx_buffer[3:2] <= rmii_rxd;
                        low_nibble_buffer <= {rmii_rxd, rx_buffer[1:0]};
                    end
                end
                
                rx_state[2]: begin // STATE_HIGH_NIBBLE
                    if (rmii_crs_dv) begin
                        rx_buffer[1:0] <= rmii_rxd;
                        mac_rx_data[3:0] <= low_nibble_buffer;
                    end
                end
                
                rx_state[3]: begin // STATE_COMPLETE
                    if (rmii_crs_dv) begin
                        rx_buffer[3:2] <= rmii_rxd;
                        mac_rx_data[7:4] <= {rmii_rxd, rx_buffer[1:0]};
                    end
                end
            endcase
        end
    end
endmodule

// TX converter: MAC 8-bit to RMII 2-bit interface
module rmii_tx_converter (
    input wire ref_clk,
    input wire rst_n,
    input wire [7:0] mac_tx_data,
    input wire mac_tx_en,
    output reg [1:0] rmii_txd,
    output reg rmii_tx_en
);
    // Gray-coded state encoding to minimize transition times
    localparam [1:0] TX_IDLE = 2'b00;
    localparam [1:0] TX_FIRST = 2'b01;
    localparam [1:0] TX_SECOND = 2'b11;
    localparam [1:0] TX_THIRD = 2'b10;
    
    reg [1:0] tx_state, tx_next_state;
    reg [7:0] tx_data_reg; // Register to store mac_tx_data to reduce input loading

    // Separate next state logic
    always @(*) begin
        // Default assignment
        tx_next_state = tx_state;
        
        if (!mac_tx_en) begin
            tx_next_state = TX_IDLE;
        end else begin
            case (tx_state)
                TX_IDLE:   tx_next_state = TX_FIRST;
                TX_FIRST:  tx_next_state = TX_SECOND;
                TX_SECOND: tx_next_state = TX_THIRD;
                TX_THIRD:  tx_next_state = TX_IDLE;
            endcase
        end
    end

    // Output selection logic - simplified and balanced
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            rmii_txd <= 2'b00;
            rmii_tx_en <= 1'b0;
            tx_state <= TX_IDLE;
            tx_data_reg <= 8'h00;
        end else begin
            // Register to reduce input loading
            tx_data_reg <= mac_tx_data;
            
            // Update state
            tx_state <= tx_next_state;
            
            // Pass through the tx enable signal directly
            rmii_tx_en <= mac_tx_en;
            
            // Output mux with no conditional logic in critical path
            if (mac_tx_en) begin
                case (tx_state)
                    TX_IDLE:   rmii_txd <= tx_data_reg[1:0];
                    TX_FIRST:  rmii_txd <= tx_data_reg[3:2];
                    TX_SECOND: rmii_txd <= tx_data_reg[5:4];
                    TX_THIRD:  rmii_txd <= tx_data_reg[7:6];
                endcase
            end else begin
                rmii_txd <= 2'b00;
            end
        end
    end
endmodule