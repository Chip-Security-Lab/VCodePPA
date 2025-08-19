//SystemVerilog
module priority_reset_dist (
    // Clock and reset
    input  wire        aclk,
    input  wire        aresetn,
    
    // Input AXI-Stream interface
    input  wire [7:0]  s_axis_tdata,   // [7:4] priority_levels, [3:0] reset_sources
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    
    // Output AXI-Stream interface
    output wire [7:0]  m_axis_tdata,   // reset_outputs
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast
);

    // Internal registers
    reg [7:0] reset_outputs_reg;
    reg       output_valid_reg;
    reg       tlast_reg;
    
    // Buffer registers for high fan-out signals
    reg       output_valid_buf1, output_valid_buf2;
    reg       tlast_buf1, tlast_buf2;
    reg [3:0] reset_sources_buf1, reset_sources_buf2;
    reg       b0_buf1, b0_buf2, b0_buf3, b0_buf4;
    
    // Ready to accept new data when output is ready or not valid
    assign s_axis_tready = ~output_valid_buf1 || m_axis_tready;
    
    // Output connections with buffered signals
    assign m_axis_tdata  = reset_outputs_reg;
    assign m_axis_tvalid = output_valid_buf2;
    assign m_axis_tlast  = tlast_buf2;
    
    // Priority encoding logic
    wire [3:0] reset_sources    = s_axis_tdata[3:0];
    wire [3:0] priority_levels  = s_axis_tdata[7:4];
    
    // Use buffer for reset_sources in complex logic
    wire       b0 = reset_sources_buf2[0]; // Buffered bit 0
    wire       b1 = reset_sources_buf2[1];
    wire       b2 = reset_sources_buf2[2];
    wire       b3 = reset_sources_buf2[3];
    
    // Split priority logic into smaller sections with buffered inputs
    wire [3:0] highest_active   = b3 ? 4'd3 :
                                  b2 ? 4'd2 :
                                  b1 ? 4'd1 :
                                  b0_buf4 ? 4'd0 : 4'd15;
                                  
    wire [7:0] reset_outputs_wire = (highest_active < 4'd15) ? 
                                   (8'hFF >> priority_levels[highest_active]) : 8'h0;
    
    // Buffer register updates for high fan-out signals
    always @(posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            // Reset all buffer registers
            output_valid_buf1 <= 1'b0;
            output_valid_buf2 <= 1'b0;
            tlast_buf1        <= 1'b0;
            tlast_buf2        <= 1'b0;
            reset_sources_buf1 <= 4'b0;
            reset_sources_buf2 <= 4'b0;
            b0_buf1           <= 1'b0;
            b0_buf2           <= 1'b0;
            b0_buf3           <= 1'b0;
            b0_buf4           <= 1'b0;
        end else begin
            // Update buffer registers for high fan-out signals
            output_valid_buf1 <= output_valid_reg;
            output_valid_buf2 <= output_valid_buf1;
            tlast_buf1        <= tlast_reg;
            tlast_buf2        <= tlast_buf1;
            reset_sources_buf1 <= reset_sources;
            reset_sources_buf2 <= reset_sources_buf1;
            
            // Multi-level buffering for bit 0 which has high fan-out
            b0_buf1 <= reset_sources_buf1[0];
            b0_buf2 <= b0_buf1;
            b0_buf3 <= b0_buf2;
            b0_buf4 <= b0_buf3;
        end
    end
    
    // Process input data - main logic
    always @(posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            reset_outputs_reg <= 8'h0;
            output_valid_reg  <= 1'b0;
            tlast_reg         <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                // New data received
                reset_outputs_reg <= reset_outputs_wire;
                output_valid_reg  <= 1'b1;
                tlast_reg         <= 1'b1;  // Each transaction is complete in one cycle
            end else if (m_axis_tready && output_valid_buf2) begin
                // Data has been accepted by downstream
                output_valid_reg  <= 1'b0;
                tlast_reg         <= 1'b0;
            end
        end
    end

endmodule