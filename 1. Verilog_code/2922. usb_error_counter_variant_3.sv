//SystemVerilog
module usb_error_counter (
    // Clock and Reset
    input  wire        aclk,
    input  wire        aresetn,
    
    // AXI-Stream Slave Interface
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire [7:0]  s_axis_tdata,
    input  wire        s_axis_tlast,
    
    // AXI-Stream Master Interface
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire [39:0] m_axis_tdata,  // Packs all 5 error counts (5*8=40 bits)
    output wire        m_axis_tlast,
    output wire [1:0]  m_axis_tuser   // Error status
);

    // Internal registers
    reg [7:0] crc_error_count;
    reg [7:0] pid_error_count;
    reg [7:0] timeout_error_count;
    reg [7:0] bitstuff_error_count;
    reg [7:0] babble_error_count;
    reg [1:0] error_status;
    reg       any_error_detected;
    
    // State definitions
    localparam NO_ERRORS = 2'b00;
    localparam WARNING   = 2'b01;
    localparam CRITICAL  = 2'b10;
    
    // Extract error flags from input data - optimized to reduce logic depth
    wire [4:0] error_flags = s_axis_tvalid ? s_axis_tdata[4:0] : 5'b0;
    wire crc_error       = error_flags[0];
    wire pid_error       = error_flags[1];
    wire timeout_error   = error_flags[2];
    wire bitstuff_error  = error_flags[3];
    wire babble_detected = error_flags[4];
    wire clear_counters  = s_axis_tvalid && s_axis_tdata[5];
    
    // Always ready to receive data
    assign s_axis_tready = 1'b1;
    
    // Pack error counts into output data
    assign m_axis_tdata = {
        babble_error_count,
        bitstuff_error_count,
        timeout_error_count,
        pid_error_count,
        crc_error_count
    };
    
    // Error status passed through tuser
    assign m_axis_tuser = error_status;
    
    // Output valid when error status changes or counts are updated
    reg m_axis_tvalid_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    
    // TLAST is high when sending the last beat of a transfer
    assign m_axis_tlast = 1'b1;
    
    // Track when we need to send an update
    reg update_needed;
    
    // Optimization: pre-compute increment condition for all counters
    wire [4:0] increment_counter;
    assign increment_counter[0] = crc_error && (crc_error_count < 8'hFF);
    assign increment_counter[1] = pid_error && (pid_error_count < 8'hFF);
    assign increment_counter[2] = timeout_error && (timeout_error_count < 8'hFF);
    assign increment_counter[3] = bitstuff_error && (bitstuff_error_count < 8'hFF);
    assign increment_counter[4] = babble_detected && (babble_error_count < 8'hFF);
    
    // Optimization: improved status determination logic
    wire is_critical_condition = (babble_error_count > 8'd3) || (timeout_error_count > 8'd10);
    wire any_error_present = |error_flags[4:0];
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            crc_error_count <= 8'd0;
            pid_error_count <= 8'd0;
            timeout_error_count <= 8'd0;
            bitstuff_error_count <= 8'd0;
            babble_error_count <= 8'd0;
            error_status <= NO_ERRORS;
            any_error_detected <= 1'b0;
            m_axis_tvalid_reg <= 1'b0;
            update_needed <= 1'b0;
        end else begin
            // Clear valid flag after successful transmission
            if (m_axis_tvalid_reg && m_axis_tready) begin
                m_axis_tvalid_reg <= 1'b0;
                update_needed <= 1'b0;
            end
            
            if (s_axis_tvalid) begin
                if (clear_counters) begin
                    // Reset all counters and status in one cycle
                    crc_error_count <= 8'd0;
                    pid_error_count <= 8'd0;
                    timeout_error_count <= 8'd0;
                    bitstuff_error_count <= 8'd0;
                    babble_error_count <= 8'd0;
                    error_status <= NO_ERRORS;
                    update_needed <= 1'b1;
                end else begin
                    // Update error flag
                    any_error_detected <= any_error_present;
                    
                    // Use pre-computed increment signals to update counters
                    if (increment_counter[0]) begin
                        crc_error_count <= crc_error_count + 8'd1;
                        update_needed <= 1'b1;
                    end
                    
                    if (increment_counter[1]) begin
                        pid_error_count <= pid_error_count + 8'd1;
                        update_needed <= 1'b1;
                    end
                    
                    if (increment_counter[2]) begin
                        timeout_error_count <= timeout_error_count + 8'd1;
                        update_needed <= 1'b1;
                    end
                    
                    if (increment_counter[3]) begin
                        bitstuff_error_count <= bitstuff_error_count + 8'd1;
                        update_needed <= 1'b1;
                    end
                    
                    if (increment_counter[4]) begin
                        babble_error_count <= babble_error_count + 8'd1;
                        update_needed <= 1'b1;
                    end
                    
                    // Optimized error status determination with faster comparisons
                    if (is_critical_condition) begin
                        if (error_status != CRITICAL) begin
                            error_status <= CRITICAL;
                            update_needed <= 1'b1;
                        end
                    end else if (any_error_detected) begin
                        if (error_status != WARNING) begin
                            error_status <= WARNING;
                            update_needed <= 1'b1;
                        end
                    end
                end
            end
            
            // Set valid when we have an update to send and aren't already sending
            if (update_needed && !m_axis_tvalid_reg) begin
                m_axis_tvalid_reg <= 1'b1;
            end
        end
    end

endmodule