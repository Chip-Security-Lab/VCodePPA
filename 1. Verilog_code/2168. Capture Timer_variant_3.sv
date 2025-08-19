//SystemVerilog
module capture_timer (
    // Clock and reset
    input  wire        clk_i,
    input  wire        rst_i,
    
    // Control signals
    input  wire        en_i,
    input  wire        capture_i,
    
    // AXI-Stream output interface
    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast
);
    // Internal signals
    reg [31:0] value_counter;
    reg [31:0] capture_value;
    reg        capture_valid;
    reg        capture_d1, capture_d2;
    reg        capture_event_r;
    wire       capture_event;
    wire       handshake_complete;
    
    // Counter logic - simplified logic path
    always @(posedge clk_i) begin
        if (rst_i)
            value_counter <= 32'h0;
        else if (en_i)
            value_counter <= value_counter + 32'h1;
    end
    
    // Edge detection registers with parallel processing
    always @(posedge clk_i) begin
        if (rst_i) begin
            capture_d1 <= 1'b0;
            capture_d2 <= 1'b0;
            capture_event_r <= 1'b0;
        end
        else begin
            capture_d1 <= capture_i;
            capture_d2 <= capture_d1;
            // Pre-compute the capture event to reduce critical path
            capture_event_r <= capture_d1 & ~capture_d2;
        end
    end
    
    // Use registered capture event to reduce combinational path
    assign capture_event = capture_event_r;
    
    // Simplified handshake detection to reduce logic depth
    assign handshake_complete = m_axis_tready & capture_valid;
    
    // Capture logic with optimized conditional logic
    always @(posedge clk_i) begin
        if (rst_i) begin
            capture_value <= 32'h0;
            capture_valid <= 1'b0;
        end
        else begin
            // Prioritized conditional structure reduces logic depth
            if (capture_event) begin
                capture_value <= value_counter;
                capture_valid <= 1'b1;
            end
            else if (handshake_complete) begin
                // Using pre-computed handshake signal
                capture_valid <= 1'b0;
            end
        end
    end
    
    // AXI-Stream interface assignments - unchanged but grouped
    assign m_axis_tdata  = capture_value;
    assign m_axis_tvalid = capture_valid;
    assign m_axis_tlast  = 1'b1;  // Each capture is treated as end of packet

endmodule