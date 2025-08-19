//SystemVerilog
module usb_packet_error_checker(
    input  wire         aclk,
    input  wire         aresetn,
    
    // AXI-Stream Slave Interface (Input)
    input  wire [7:0]   s_axis_tdata,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    input  wire         s_axis_tlast,
    input  wire [15:0]  s_axis_tuser,  // Received CRC value
    
    // AXI-Stream Master Interface (Output)
    output wire [2:0]   m_axis_tdata,  // Error flags [crc_error, timeout_error, bitstuff_error]
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tlast
);
    
    // Internal registers
    reg [15:0] calculated_crc;
    reg [7:0]  timeout_counter;
    reg        receiving;
    reg        crc_error_reg;
    reg        timeout_error_reg;
    reg        bitstuff_error_reg;
    reg        result_valid;
    reg        result_sent;
    
    // Simplified CRC-16 calculation
    wire [15:0] next_crc = {calculated_crc[14:0], 1'b0} ^ 
                          (calculated_crc[15] ? 16'h8005 : 16'h0000);
    
    // AXI-Stream handshaking
    assign s_axis_tready = aresetn && !result_valid; // Ready to receive when not processing results
    assign m_axis_tdata = {crc_error_reg, timeout_error_reg, bitstuff_error_reg};
    assign m_axis_tvalid = result_valid && !result_sent;
    assign m_axis_tlast = 1'b1; // Each error report is a single transfer
    
    // Main processing logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            calculated_crc <= 16'hFFFF;
            timeout_counter <= 8'd0;
            crc_error_reg <= 1'b0;
            timeout_error_reg <= 1'b0;
            bitstuff_error_reg <= 1'b0;
            receiving <= 1'b0;
            result_valid <= 1'b0;
            result_sent <= 1'b0;
        end else begin
            // Process data when valid and we're ready
            if (s_axis_tvalid && s_axis_tready) begin
                calculated_crc <= calculated_crc ^ {8'h00, s_axis_tdata};
                timeout_counter <= 8'd0;
                receiving <= 1'b1;
                
                // Check for packet end
                if (s_axis_tlast) begin
                    crc_error_reg <= (calculated_crc != s_axis_tuser);
                    calculated_crc <= 16'hFFFF;
                    receiving <= 1'b0;
                    result_valid <= 1'b1;
                    result_sent <= 1'b0;
                end
            end else if (receiving) begin
                // Handle timeout detection
                timeout_counter <= timeout_counter + 1'b1;
                if (timeout_counter > 8'd200) begin
                    timeout_error_reg <= 1'b1;
                    receiving <= 1'b0;
                    result_valid <= 1'b1;
                    result_sent <= 1'b0;
                    calculated_crc <= 16'hFFFF;
                end
            end
            
            // Handle result transmission
            if (result_valid && m_axis_tvalid && m_axis_tready) begin
                result_sent <= 1'b1;
                result_valid <= 1'b0;
                crc_error_reg <= 1'b0;
                timeout_error_reg <= 1'b0;
                bitstuff_error_reg <= 1'b0;
            end
        end
    end
    
endmodule