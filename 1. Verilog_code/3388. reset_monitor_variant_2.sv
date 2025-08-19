//SystemVerilog
module reset_monitor (
    // Clock and reset
    input  wire        clk,
    
    // AXI-Stream input interface
    input  wire [3:0]  s_axis_tdata,    // Reset inputs as AXI-Stream data
    input  wire        s_axis_tvalid,   // Input data valid signal
    output wire        s_axis_tready,   // Ready to accept input
    
    // AXI-Stream output interface
    output wire [3:0]  m_axis_tdata,    // Reset outputs as AXI-Stream data
    output reg         m_axis_tvalid,   // Output data valid signal
    input  wire        m_axis_tready,   // Downstream ready to accept
    
    // Status output (maintained for compatibility)
    output reg  [3:0]  reset_status
);

    // Internal registers
    reg [3:0] reset_data_reg;
    
    // Always ready to accept new data
    assign s_axis_tready = 1'b1;
    
    // Pass reset data to output
    assign m_axis_tdata = reset_data_reg;
    
    // Control signals for case statement
    wire input_handshake;
    wire output_handshake;
    
    assign input_handshake = s_axis_tvalid && s_axis_tready;
    assign output_handshake = m_axis_tvalid && m_axis_tready;
    
    always @(posedge clk) begin
        case ({input_handshake, output_handshake})
            2'b10: begin
                // Capture input data when valid input handshake occurs
                reset_data_reg <= s_axis_tdata;
                reset_status   <= s_axis_tdata;  // Track which resets were activated
                m_axis_tvalid  <= 1'b1;          // Signal valid output data
            end
            
            2'b01: begin
                // Clear valid flag after successful output handshake
                m_axis_tvalid  <= 1'b0;
            end
            
            2'b11: begin
                // Handle simultaneous handshakes - prioritize input
                reset_data_reg <= s_axis_tdata;
                reset_status   <= s_axis_tdata;
                m_axis_tvalid  <= 1'b1;
            end
            
            default: begin
                // No handshakes - maintain current state
            end
        endcase
    end

endmodule