//SystemVerilog
module usb_phy_interface(
    input wire clk,
    input wire rst_n,
    
    // UTMI Interface
    input wire [7:0] DataOut,
    input wire TxValid,
    output reg TxReady,
    output reg [7:0] DataIn,
    output reg RxValid,
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
    
    // Tri-state buffer logic for D+/D-
    assign dp = dp_oe ? dp_out : 1'bz;
    assign dm = dm_oe ? dm_out : 1'bz;
    assign dp_in = dp;
    assign dm_in = dm;
    
    // PHY state machine with one-hot encoding
    localparam IDLE = 3'b001;
    localparam RX   = 3'b010;
    localparam TX   = 3'b100;
    
    reg [2:0] phy_state, next_phy_state;
    reg [2:0] bit_count, next_bit_count;
    reg [7:0] shift_reg, next_shift_reg;
    
    // State transition logic
    always @(*) begin
        next_phy_state = phy_state;
        next_bit_count = bit_count;
        next_shift_reg = shift_reg;
        
        case (1'b1) // Case statement based on one-hot encoding
            phy_state[0]: begin // IDLE
                if (TxValid) begin
                    next_phy_state = TX;
                    next_shift_reg = DataOut;
                    next_bit_count = 3'd0;
                end else if (dp_in != dm_in) begin
                    next_phy_state = RX;
                    next_bit_count = 3'd0;
                end
            end
            // Additional states would be implemented here
            default: next_phy_state = IDLE;
        endcase
    end
    
    // State register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phy_state <= IDLE;
            bit_count <= 3'd0;
            shift_reg <= 8'd0;
        end else begin
            phy_state <= next_phy_state;
            bit_count <= next_bit_count;
            shift_reg <= next_shift_reg;
        end
    end
    
    // UTMI transmit control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            TxReady <= 1'b0;
        end else begin
            case (1'b1) // Case statement based on one-hot encoding
                phy_state[0]: TxReady <= 1'b1; // IDLE
                phy_state[2]: TxReady <= 1'b0; // TX
                default: TxReady <= 1'b0;
            endcase
        end
    end
    
    // UTMI receive control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            RxActive <= 1'b0;
            RxValid <= 1'b0;
            RxError <= 1'b0;
            DataIn <= 8'd0;
        end else begin
            case (1'b1) // Case statement based on one-hot encoding
                phy_state[0]: begin // IDLE
                    RxActive <= 1'b0;
                    RxValid <= 1'b0;
                end
                phy_state[1]: begin // RX
                    RxActive <= 1'b1;
                    // RxValid and DataIn would be set based on reception logic
                end
                default: begin
                    RxActive <= RxActive;
                    RxValid <= RxValid;
                end
            endcase
        end
    end
    
    // Differential pair output control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dp_out <= 1'b1;  // Idle J state
            dm_out <= 1'b0;
            dp_oe <= 1'b0;
            dm_oe <= 1'b0;
        end else begin
            case (1'b1) // Case statement based on one-hot encoding
                phy_state[0]: begin // IDLE
                    if (!SuspendM) begin
                        dp_oe <= 1'b0;
                        dm_oe <= 1'b0;
                    end else if (XcvrSelect && TermSelect) begin  // Full-speed
                        dp_oe <= 1'b1;
                        dm_oe <= 1'b1;
                        dp_out <= 1'b1;  // J state
                        dm_out <= 1'b0;
                    end
                end
                phy_state[2]: begin // TX
                    dp_oe <= 1'b1;
                    dm_oe <= 1'b1;
                    // dp_out and dm_out would be set based on the shift register
                end
                default: begin
                    // Maintain previous values
                    dp_oe <= dp_oe;
                    dm_oe <= dm_oe;
                end
            endcase
        end
    end
    
    // Line state monitoring
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            LineState <= 1'b0;
        end else begin
            LineState <= {dp_in, dm_in};
        end
    end
    
endmodule