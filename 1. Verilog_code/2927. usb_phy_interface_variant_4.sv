//SystemVerilog
module usb_phy_interface(
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream Interface (Output)
    output reg [7:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg m_axis_tlast,
    
    // AXI-Stream Interface (Input)
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    input wire s_axis_tlast,
    
    // Line State Control
    input wire OpMode,
    input wire XcvrSelect,
    input wire TermSelect,
    input wire SuspendM,
    output reg [1:0] LineState,
    
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
    
    // PHY state machine definitions
    localparam IDLE = 2'b00;
    localparam RX = 2'b01;
    localparam TX = 2'b10;
    
    reg [1:0] phy_state;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;
    reg rx_error_flag;
    
    // Line state detection - optimized comparison
    wire line_activity = dp_in ^ dm_in; // XOR for detecting differential state
    wire [1:0] line_state_bus = {dp_in, dm_in};
    
    // Packet end detection logic
    reg packet_end;
    reg [2:0] idle_count;
    
    // Synchronous reset with active state assignments
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phy_state <= IDLE;
            s_axis_tready <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 8'd0;
            m_axis_tlast <= 1'b0;
            rx_error_flag <= 1'b0;
            dp_out <= 1'b1;  // Idle J state
            dm_out <= 1'b0;
            dp_oe <= 1'b0;
            dm_oe <= 1'b0;
            LineState <= 2'b00;
            bit_count <= 3'd0;
            shift_reg <= 8'd0;
            packet_end <= 1'b0;
            idle_count <= 3'd0;
        end
        else begin
            // Default values for single-cycle signals
            m_axis_tlast <= 1'b0;
            
            // State transition logic - combined with control signals
            case (phy_state)
                IDLE: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        phy_state <= TX;
                        s_axis_tready <= 1'b0;
                        shift_reg <= s_axis_tdata;
                        bit_count <= 3'd0;
                        packet_end <= s_axis_tlast;
                    end 
                    else begin
                        s_axis_tready <= 1'b1;
                        if (line_activity) begin // Activity detected using pre-computed signal
                            phy_state <= RX;
                            m_axis_tvalid <= 1'b0;
                            idle_count <= 3'd0;
                        end
                    end
                    
                    // RX control signal updates
                    if (!line_activity) begin
                        m_axis_tvalid <= 1'b0;
                    end
                    
                    // Line state control logic (optimized)
                    if (!SuspendM) begin
                        dp_oe <= 1'b0;
                        dm_oe <= 1'b0;
                    end 
                    else if (XcvrSelect && TermSelect) begin // Full-speed condition
                        dp_oe <= 1'b1;
                        dm_oe <= 1'b1;
                        dp_out <= 1'b1;  // J state
                        dm_out <= 1'b0;
                    end
                    
                    LineState <= line_state_bus;
                end
                
                RX: begin
                    // Sample data and build byte for AXI-Stream output
                    if (bit_count < 3'd7) begin
                        shift_reg <= {shift_reg[6:0], dp_in};
                        bit_count <= bit_count + 1'b1;
                    end
                    else begin
                        // Complete byte received
                        m_axis_tdata <= {shift_reg[6:0], dp_in};
                        m_axis_tvalid <= 1'b1;
                        bit_count <= 3'd0;
                        
                        // Check for packet end condition
                        if (!line_activity) begin
                            idle_count <= idle_count + 1'b1;
                            if (idle_count >= 3'd3) begin
                                m_axis_tlast <= 1'b1;
                                phy_state <= IDLE;
                                idle_count <= 3'd0;
                            end
                        end
                        else begin
                            idle_count <= 3'd0;
                        end
                        
                        // Handle backpressure
                        if (!m_axis_tready) begin
                            // Hold current data until ready
                            bit_count <= bit_count;
                        end
                    end
                    
                    // Error detection logic
                    rx_error_flag <= (dp_in == dm_in) && line_activity;
                    
                    LineState <= line_state_bus;
                end
                
                TX: begin
                    // Setup for transmission
                    dp_oe <= 1'b1;
                    dm_oe <= 1'b1;
                    
                    // Transmit bit by bit
                    if (bit_count < 3'd7) begin
                        // Differential signaling based on bit value
                        dp_out <= shift_reg[bit_count];
                        dm_out <= ~shift_reg[bit_count];
                        bit_count <= bit_count + 1'b1;
                    end
                    else begin
                        // Transmit last bit
                        dp_out <= shift_reg[7];
                        dm_out <= ~shift_reg[7];
                        
                        // Ready for next data byte
                        s_axis_tready <= 1'b1;
                        
                        // Check if more data is available
                        if (s_axis_tvalid) begin
                            shift_reg <= s_axis_tdata;
                            bit_count <= 3'd0;
                            packet_end <= s_axis_tlast;
                            s_axis_tready <= 1'b0;
                        end
                        else if (packet_end) begin
                            // End of packet, return to idle
                            phy_state <= IDLE;
                            s_axis_tready <= 1'b1;
                            // Send EOP (End of Packet)
                            dp_out <= 1'b0;
                            dm_out <= 1'b0;
                        end
                    end
                end
                
                default: begin
                    phy_state <= IDLE;
                end
            endcase
        end
    end
endmodule