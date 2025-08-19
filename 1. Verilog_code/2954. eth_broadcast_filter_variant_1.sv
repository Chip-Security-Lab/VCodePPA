//SystemVerilog
module eth_broadcast_filter (
    // Clock and reset signals
    input  wire        aclk,
    input  wire        aresetn,
    
    // AXI-Stream input interface
    input  wire [7:0]  s_axis_tdata,
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tlast,
    output wire        s_axis_tready,
    
    // AXI-Stream output interface
    output reg  [7:0]  m_axis_tdata,
    output reg         m_axis_tvalid,
    output reg         m_axis_tlast,
    input  wire        m_axis_tready,
    
    // Control signals
    output reg         broadcast_detected,
    input  wire        pass_broadcast
);
    
    // Internal signals and registers
    reg  [5:0]  byte_counter;
    reg         broadcast_frame;
    reg  [47:0] dest_mac;
    wire        frame_start;
    reg         frame_in_progress;
    wire        input_handshake;
    wire        output_handshake;
    wire        should_output_data;
    wire        is_ff_byte;
    wire        mac_capture_phase;
    wire        mac_complete;
    
    // AXI handshake signals
    assign s_axis_tready = m_axis_tready || !should_output_data;
    assign input_handshake = s_axis_tvalid && s_axis_tready;
    assign output_handshake = m_axis_tvalid && m_axis_tready;
    
    // Frame start detection (s_axis_tlast falling edge detection)
    assign frame_start = input_handshake && !frame_in_progress && !s_axis_tlast;
    
    // Signal processing logic
    assign mac_capture_phase = (byte_counter < 6);
    assign mac_complete = (byte_counter == 6);
    assign is_ff_byte = (s_axis_tdata == 8'hFF);
    assign should_output_data = (pass_broadcast || !broadcast_detected);
    
    // Main state machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            reset_module_state();
        end else begin
            // Track frame progress
            if (frame_start) begin
                frame_in_progress <= 1'b1;
                reset_frame_state();
            end else if (input_handshake && s_axis_tlast) begin
                frame_in_progress <= 1'b0;
            end
            
            // Handle data processing
            if (input_handshake) begin
                // Pass through data
                m_axis_tdata <= s_axis_tdata;
                m_axis_tlast <= s_axis_tlast;
                
                process_data();
            end
            
            // Handle back pressure
            if (m_axis_tready) begin
                if (!input_handshake) begin
                    m_axis_tvalid <= 1'b0;
                end
            end
        end
    end
    
    // Task: Reset all module state
    task reset_module_state;
        begin
            byte_counter <= 6'd0;
            broadcast_frame <= 1'b0;
            broadcast_detected <= 1'b0;
            dest_mac <= 48'd0;
            frame_in_progress <= 1'b0;
            
            // AXI interface signals
            m_axis_tdata <= 8'd0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
        end
    endtask
    
    // Task: Reset frame processing state
    task reset_frame_state;
        begin
            byte_counter <= 6'd0;
            broadcast_frame <= 1'b0;
            broadcast_detected <= 1'b0;
        end
    endtask
    
    // Task: Process input data
    task process_data;
        begin
            if (mac_capture_phase) begin
                process_mac_byte();
            end else begin
                process_payload();
            end
        end
    endtask
    
    // Task: Process MAC address byte
    task process_mac_byte;
        begin
            // Capture destination MAC address (first 6 bytes)
            dest_mac <= {dest_mac[39:0], s_axis_tdata};
            byte_counter <= byte_counter + 1'b1;
            
            // Check if this byte is 0xFF (part of broadcast address)
            if (!is_ff_byte) begin
                broadcast_frame <= 1'b0;
            end else if (byte_counter == 0) begin
                // First byte is 0xFF, potentially a broadcast frame
                broadcast_frame <= 1'b1;
            end
            
            // Only output data when passing broadcasts or not a broadcast frame
            m_axis_tvalid <= (pass_broadcast || !broadcast_frame);
        end
    endtask
    
    // Task: Process payload data
    task process_payload;
        begin
            if (mac_complete && broadcast_frame) begin
                // Destination MAC address read and all FF
                broadcast_detected <= 1'b1;
            end
            
            // Only output data when passing broadcasts or not a broadcast frame
            m_axis_tvalid <= should_output_data;
        end
    endtask
    
endmodule