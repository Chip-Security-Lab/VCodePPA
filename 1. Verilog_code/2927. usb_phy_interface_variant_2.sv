//SystemVerilog
module usb_phy_interface(
    input wire clk,
    input wire rst_n,
    
    // UTMI Interface with Valid-Ready handshaking
    input wire [7:0] DataOut,
    input wire DataOut_valid,    // Previously TxValid
    output reg DataOut_ready,    // Previously TxReady
    output reg [7:0] DataIn,
    output reg DataIn_valid,     // Previously RxValid
    input wire DataIn_ready,     // New signal for handshaking
    output reg RxActive,
    output reg RxError,
    
    // Line State Control
    input wire OpMode,
    input wire XcvrSelect,
    input wire TermSelect,
    input wire SuspendM,
    output reg LineState,
    
    // USB Differential Pair (external)
    inout wire dp,
    inout wire dm
);
    // Internal signals
    reg dp_out, dm_out;
    reg dp_oe, dm_oe;
    wire dp_in, dm_in;
    
    // Input stage registers - moved after combinational logic
    reg SuspendM_r;
    reg XcvrSelect_r;
    reg TermSelect_r;
    reg DataOut_valid_r;
    reg [7:0] DataOut_r;
    reg DataIn_ready_r;
    
    // Data transfer tracking signals
    reg data_out_consumed;
    reg data_in_transferred;
    
    // Pre-registered input signals
    wire dp_activity;
    wire fs_mode;
    
    // Capture inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            SuspendM_r <= 1'b0;
            XcvrSelect_r <= 1'b0;
            TermSelect_r <= 1'b0;
            DataOut_valid_r <= 1'b0;
            DataOut_r <= 8'd0;
            DataIn_ready_r <= 1'b0;
        end else begin
            SuspendM_r <= SuspendM;
            XcvrSelect_r <= XcvrSelect;
            TermSelect_r <= TermSelect;
            DataOut_valid_r <= DataOut_valid;
            DataOut_r <= DataOut;
            DataIn_ready_r <= DataIn_ready;
        end
    end
    
    // Tri-state buffer logic for D+/D-
    assign dp = dp_oe ? dp_out : 1'bz;
    assign dm = dm_oe ? dm_out : 1'bz;
    assign dp_in = dp;
    assign dm_in = dm;
    
    // Pre-compute combinational signals
    assign dp_activity = (dp_in != dm_in);
    assign fs_mode = XcvrSelect_r && TermSelect_r;
    
    // PHY state machine - One-hot encoding
    localparam IDLE = 3'b001;
    localparam RX   = 3'b010;
    localparam TX   = 3'b100;
    
    reg [2:0] phy_state;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phy_state <= IDLE;
            DataOut_ready <= 1'b1;   // Ready to accept data
            DataIn_valid <= 1'b0;    // No data to send
            RxActive <= 1'b0;
            RxError <= 1'b0;
            dp_out <= 1'b1;          // Idle J state
            dm_out <= 1'b0;
            dp_oe <= 1'b0;
            dm_oe <= 1'b0;
            LineState <= 1'b0;
            bit_count <= 3'd0;
            shift_reg <= 8'd0;
            data_out_consumed <= 1'b0;
            data_in_transferred <= 1'b0;
            DataIn <= 8'd0;
        end else begin
            // Default values
            data_out_consumed <= 1'b0;
            data_in_transferred <= 1'b0;
            
            case (phy_state)
                IDLE: begin
                    // Transmit condition - Valid data is available and we're ready
                    if (DataOut_valid_r && DataOut_ready) begin
                        phy_state <= TX;
                        DataOut_ready <= 1'b0;  // Not ready for more data until current is processed
                        dp_oe <= 1'b1;
                        dm_oe <= 1'b1;
                        shift_reg <= DataOut_r;
                        bit_count <= 3'd0;
                        data_out_consumed <= 1'b1;  // Mark that we've consumed the data
                    end else if (dp_activity) begin  // Activity detected on bus
                        phy_state <= RX;
                        RxActive <= 1'b1;
                        bit_count <= 3'd0;
                        DataIn_valid <= 1'b0;   // Will become valid when data is received
                    end else begin
                        DataOut_ready <= 1'b1;  // Ready to accept new data
                        RxActive <= 1'b0;
                        
                        // Only clear valid if data has been acknowledged
                        if (DataIn_valid && DataIn_ready_r) begin
                            DataIn_valid <= 1'b0;
                            data_in_transferred <= 1'b1;
                        end
                        
                        // Set line state based on SuspendM
                        if (!SuspendM_r) begin
                            dp_oe <= 1'b0;
                            dm_oe <= 1'b0;
                        end else if (fs_mode) begin  // Full-speed
                            dp_oe <= 1'b1;
                            dm_oe <= 1'b1;
                            dp_out <= 1'b1;  // J state
                            dm_out <= 1'b0;
                        end
                        LineState <= {dp_in, dm_in};
                    end
                end
                
                // TX and RX states would be implemented here with valid-ready handshaking...
                // For TX state: Only indicate ready for new data when current transfer completes
                // For RX state: Set DataIn_valid when data is ready, wait for DataIn_ready acknowledgment
            endcase
        end
    end
endmodule