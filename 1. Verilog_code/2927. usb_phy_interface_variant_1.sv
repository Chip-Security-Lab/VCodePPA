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
            TxReady <= 1'b0;
            RxValid <= 1'b0;
            RxActive <= 1'b0;
            RxError <= 1'b0;
            dp_out <= 1'b1;  // Idle J state
            dm_out <= 1'b0;
            dp_oe <= 1'b0;
            dm_oe <= 1'b0;
            LineState <= 1'b0;
            bit_count <= 3'd0;
            shift_reg <= 8'd0;
        end else begin
            // Default state transitions (remain in current state)
            phy_state <= phy_state;
            
            case (phy_state)
                IDLE: begin
                    case ({TxValid, (dp_in != dm_in)})
                        2'b10: begin  // TxValid is active
                            phy_state <= TX;
                            TxReady <= 1'b0;
                            dp_oe <= 1'b1;
                            dm_oe <= 1'b1;
                            shift_reg <= DataOut;
                            bit_count <= 3'd0;
                        end
                        2'b01: begin  // Activity detected
                            phy_state <= RX;
                            RxActive <= 1'b1;
                            bit_count <= 3'd0;
                        end
                        default: begin  // No activity, stay in IDLE
                            TxReady <= 1'b1;
                            RxActive <= 1'b0;
                            RxValid <= 1'b0;
                            
                            case ({SuspendM, XcvrSelect && TermSelect})
                                2'b00, 2'b01: begin  // !SuspendM
                                    dp_oe <= 1'b0;
                                    dm_oe <= 1'b0;
                                end
                                2'b10, 2'b11: begin  // SuspendM and (XcvrSelect && TermSelect)
                                    if (XcvrSelect && TermSelect) begin  // Full-speed
                                        dp_oe <= 1'b1;
                                        dm_oe <= 1'b1;
                                        dp_out <= 1'b1;  // J state
                                        dm_out <= 1'b0;
                                    end
                                end
                            endcase
                            LineState <= {dp_in, dm_in};
                        end
                    endcase
                end
                
                RX: begin
                    // RX state (one-hot bit 1) implementation would go here
                end
                
                TX: begin
                    // TX state (one-hot bit 2) implementation would go here
                end
                
                default: begin
                    phy_state <= IDLE;  // Safety: return to IDLE in case of invalid state
                end
            endcase
        end
    end
endmodule