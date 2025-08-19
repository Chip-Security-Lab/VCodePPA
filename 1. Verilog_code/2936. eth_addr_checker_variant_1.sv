//SystemVerilog
module eth_addr_checker (
    input wire clk,
    input wire reset_n,
    
    // AXI-Stream Slave Interface
    input wire [47:0] s_axis_tdata,     // Contains received_addr
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // Configuration input (can be from register interface)
    input wire [47:0] mac_addr,
    
    // AXI-Stream Master Interface
    output wire [2:0] m_axis_tdata,     // {addr_match, broadcast_detected, multicast_detected}
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire m_axis_tlast            // Indicates end of packet check
);
    // Internal signals
    reg [47:0] mac_addr_reg;
    reg [47:0] received_addr_reg;
    reg processing_valid;
    
    // Intermediate results
    reg addr_match_comb;
    reg broadcast_detected_comb;
    reg multicast_detected_comb;
    
    // Output registers
    reg addr_match;
    reg broadcast_detected;
    reg multicast_detected;
    reg output_valid;
    reg output_last;
    
    // State machine registers
    reg ready_for_input;
    
    // Input handshaking
    assign s_axis_tready = ready_for_input;
    
    // Output handshaking
    assign m_axis_tdata = {addr_match, broadcast_detected, multicast_detected};
    assign m_axis_tvalid = output_valid;
    assign m_axis_tlast = output_last;
    
    // State management and input registration
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mac_addr_reg <= 48'h0;
            received_addr_reg <= 48'h0;
            processing_valid <= 1'b0;
            ready_for_input <= 1'b1;
        end else begin
            mac_addr_reg <= mac_addr;
            
            // Input data capture on valid handshake
            if (s_axis_tvalid && s_axis_tready) begin
                received_addr_reg <= s_axis_tdata;
                processing_valid <= 1'b1;
                ready_for_input <= 1'b0;  // Stop accepting data until processing completes
            end
            
            // Clear processing flag when output is accepted
            if (m_axis_tvalid && m_axis_tready) begin
                processing_valid <= 1'b0;
                ready_for_input <= 1'b1;  // Ready for next input
            end
        end
    end
    
    // Address check combinational logic
    always @(*) begin
        if (processing_valid) begin
            addr_match_comb = (mac_addr_reg == received_addr_reg);
            broadcast_detected_comb = &received_addr_reg[47:0];
            multicast_detected_comb = received_addr_reg[0];
        end else begin
            addr_match_comb = 1'b0;
            broadcast_detected_comb = 1'b0;
            multicast_detected_comb = 1'b0;
        end
    end
    
    // Output registers with backpressure handling
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            addr_match <= 1'b0;
            broadcast_detected <= 1'b0;
            multicast_detected <= 1'b0;
            output_valid <= 1'b0;
            output_last <= 1'b0;
        end else begin
            // Update output data when processing is valid
            if (processing_valid && !output_valid) begin
                addr_match <= addr_match_comb;
                broadcast_detected <= broadcast_detected_comb;
                multicast_detected <= multicast_detected_comb;
                output_valid <= 1'b1;
                output_last <= 1'b1;  // Each address check is one transaction
            end
            
            // Clear output valid when data is accepted
            if (m_axis_tvalid && m_axis_tready) begin
                output_valid <= 1'b0;
                output_last <= 1'b0;
            end
        end
    end
endmodule