//SystemVerilog
module usb_frame_counter (
    // Clock and Reset
    input  wire        clk,
    input  wire        rst_n,
    
    // AXI-Stream Slave Interface
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tlast,
    
    // AXI-Stream Master Interface
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tlast
);
    // Internal signals mapping from AXI-Stream input
    wire        sof_received = s_axis_tvalid && s_axis_tready && s_axis_tdata[0];
    wire        frame_error = s_axis_tvalid && s_axis_tready && s_axis_tdata[1];
    wire [10:0] frame_number = s_axis_tdata[12:2];
    
    // Output signals to be mapped to AXI-Stream output
    reg [10:0] expected_frame;
    reg        frame_missed;
    reg        frame_mismatch;
    reg [15:0] sof_count;
    reg [15:0] error_count;
    wire [1:0] counter_status;
    
    // Internal signals for processing
    reg [15:0] consecutive_good;
    reg        initialized;
    
    // Pipelining registers to improve timing
    reg        sof_received_r;
    reg        frame_error_r;
    reg [10:0] frame_number_r;
    
    // Multi-stage buffers to reduce fanout and improve PPA
    reg [15:0] error_count_buf1, error_count_buf2;
    reg [10:0] frame_number_r_buf1, frame_number_r_buf2;
    
    // Optimize buffer signals for complex logic paths
    reg        b0;  // Buffer signal for initialization logic
    reg        d0, d1;  // Buffer signals for decision paths
    reg [1:0]  d0_buf, d1_buf;  // Additional buffers for decision paths
    
    // AXI-Stream handshaking logic
    reg        m_axis_tvalid_r;
    reg [31:0] m_axis_tdata_r;
    reg        m_axis_tlast_r;
    reg        s_ready_r;
    
    // Always ready to receive new data unless processing is stalled
    assign s_axis_tready = s_ready_r;
    
    // Master interface connections
    assign m_axis_tvalid = m_axis_tvalid_r;
    assign m_axis_tdata = m_axis_tdata_r;
    assign m_axis_tlast = m_axis_tlast_r;
    
    // Status output based on error counts with buffered signals
    assign counter_status = (error_count_buf1 > 16'd10) ? 2'b11 :  // Critical errors
                           (error_count_buf1 > 16'd0)  ? 2'b01 :  // Warning
                           2'b00;                                 // Good
    
    // AXI-Stream ready logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_ready_r <= 1'b1;
        end else begin
            // Ready to accept data if master is ready to receive or not valid
            s_ready_r <= !m_axis_tvalid_r || m_axis_tready;
        end
    end
    
    // Register input signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sof_received_r <= 1'b0;
            frame_error_r <= 1'b0;
            frame_number_r <= 11'd0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            sof_received_r <= s_axis_tdata[0];
            frame_error_r <= s_axis_tdata[1];
            frame_number_r <= s_axis_tdata[12:2];
        end
    end
    
    // Buffer stages for high fanout signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_count_buf1 <= 16'd0;
            error_count_buf2 <= 16'd0;
            frame_number_r_buf1 <= 11'd0;
            frame_number_r_buf2 <= 11'd0;
            b0 <= 1'b0;
            d0 <= 1'b0;
            d1 <= 1'b0;
            d0_buf <= 2'b0;
            d1_buf <= 2'b0;
        end else begin
            // Buffer high fanout signals across multiple stages
            error_count_buf1 <= error_count;
            error_count_buf2 <= error_count_buf1;
            frame_number_r_buf1 <= frame_number_r;
            frame_number_r_buf2 <= frame_number_r_buf1;
            
            // Buffer for initialization logic
            b0 <= !initialized;
            
            // Buffers for decision paths
            d0 <= (frame_number_r != expected_frame);
            d1 <= (frame_number_r == expected_frame);
            d0_buf <= {d0, d0};
            d1_buf <= {d1, d1};
        end
    end
    
    // Main processing logic with registered inputs and buffered signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            expected_frame <= 11'd0;
            frame_missed <= 1'b0;
            frame_mismatch <= 1'b0;
            sof_count <= 16'd0;
            error_count <= 16'd0;
            consecutive_good <= 16'd0;
            initialized <= 1'b0;
        end else begin
            // Clear single-cycle flags
            frame_missed <= 1'b0;
            frame_mismatch <= 1'b0;
            
            if (sof_received_r) begin
                sof_count <= sof_count + 16'd1;
                
                if (b0) begin
                    // First SOF received - initialize expected counter
                    expected_frame <= frame_number_r_buf1;
                    initialized <= 1'b1;
                    consecutive_good <= 16'd1;
                end else begin
                    // Check if received frame matches expected using buffered path
                    if (d0_buf[0]) begin
                        frame_mismatch <= 1'b1;
                        error_count <= error_count + 16'd1;
                        consecutive_good <= 16'd0;
                    end else if (d1_buf[0]) begin
                        consecutive_good <= consecutive_good + 16'd1;
                    end
                    
                    // Update expected frame for next SOF
                    expected_frame <= (frame_number_r_buf2 + 11'd1) & 11'h7FF;
                end
            end else if (frame_error_r) begin
                error_count <= error_count + 16'd1;
                consecutive_good <= 16'd0;
            end
        end
    end
    
    // AXI-Stream output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid_r <= 1'b0;
            m_axis_tdata_r <= 32'd0;
            m_axis_tlast_r <= 1'b0;
        end else begin
            if (!m_axis_tvalid_r || m_axis_tready) begin
                // When ready to send new data
                m_axis_tvalid_r <= 1'b1;
                
                // Pack output data into AXI-Stream data bus
                m_axis_tdata_r <= {
                    counter_status,        // [31:30]
                    error_count[15:0],     // [29:14]
                    expected_frame[10:0],  // [13:3]
                    frame_mismatch,        // [2]
                    frame_missed,          // [1]
                    initialized            // [0]
                };
                
                // Assert TLAST after every complete status update
                m_axis_tlast_r <= 1'b1;
            end else if (m_axis_tvalid_r && m_axis_tready) begin
                // Once current data is accepted, prepare for next transfer
                m_axis_tvalid_r <= 1'b0;
                m_axis_tlast_r <= 1'b0;
            end
        end
    end
endmodule