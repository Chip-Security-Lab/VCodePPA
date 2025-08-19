//SystemVerilog
module rz_codec (
    input wire clk, rst_n,
    
    // Input AXI-Stream interface
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire s_axis_tdata,   // Single bit data input for encoding
    input wire s_axis_tlast,
    
    // Output AXI-Stream interface for RZ encoded data
    output reg m_axis_rz_tvalid,
    input wire m_axis_rz_tready,
    output reg m_axis_rz_tdata,  // RZ encoded output
    output reg m_axis_rz_tlast,
    
    // Output AXI-Stream interface for decoded data
    output reg m_axis_data_tvalid,
    input wire m_axis_data_tready,
    output reg m_axis_data_tdata,  // Decoded output
    output reg m_axis_data_tlast
);
    // RZ encoding: '1' is encoded as high-low, '0' is encoded as low-low
    reg [1:0] bit_phase;
    reg s_data_captured;      // Flag indicating we've captured input data
    
    // Input handshaking logic - moved before register
    wire input_handshake = s_axis_tvalid && s_axis_tready;
    
    // Ready signal - we're ready when in phase 0 and output stream is ready
    assign s_axis_tready = (bit_phase == 2'b00) && m_axis_rz_tready && !s_data_captured;
    
    // Bit phase counter with improved reset condition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_phase <= 2'b00;
            s_data_captured <= 1'b0;
        end
        else begin
            if (bit_phase == 2'b11 && m_axis_rz_tvalid && m_axis_rz_tready) begin
                bit_phase <= 2'b00;
                s_data_captured <= 1'b0; // Reset capture flag after complete cycle
            end
            else if (bit_phase == 2'b00 && input_handshake) begin
                s_data_captured <= 1'b1; // Set capture flag
                bit_phase <= 2'b01;      // Advance to first phase immediately
            end
            else if (m_axis_rz_tvalid && m_axis_rz_tready && bit_phase != 2'b11) begin
                bit_phase <= bit_phase + 1'b1;
            end
        end
    end
    
    // RZ encoder output data generation - moved register logic into data path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_rz_tdata <= 1'b0;
        end
        else if (m_axis_rz_tvalid && m_axis_rz_tready) begin
            case (bit_phase)
                2'b00: m_axis_rz_tdata <= s_axis_tdata; // Direct from input to output, no register
                2'b01: m_axis_rz_tdata <= m_axis_rz_tdata; // Hold first half
                2'b10: m_axis_rz_tdata <= 1'b0;        // Second half always returns to zero
                2'b11: m_axis_rz_tdata <= 1'b0;        // Keep at zero
            endcase
        end
    end
    
    // Output valid logic - simplified
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_rz_tvalid <= 1'b0;
        end
        else begin
            if (input_handshake && bit_phase == 2'b00) begin
                m_axis_rz_tvalid <= 1'b1;
            end
            else if (m_axis_rz_tready && bit_phase == 2'b11) begin
                m_axis_rz_tvalid <= 1'b0;
            end
        end
    end
    
    // TLAST handling for RZ output - moved register logic into direct path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_rz_tlast <= 1'b0;
        end
        else begin
            if (m_axis_rz_tvalid && m_axis_rz_tready && bit_phase == 2'b11) begin
                m_axis_rz_tlast <= s_axis_tlast; // Direct from input to output at end of cycle
            end
            else if (m_axis_rz_tvalid && m_axis_rz_tready && m_axis_rz_tlast) begin
                m_axis_rz_tlast <= 1'b0;
            end
        end
    end
    
    // Initialize decoded output interface signals
    initial begin
        m_axis_data_tvalid = 1'b0;
        m_axis_data_tdata = 1'b0;
        m_axis_data_tlast = 1'b0;
    end
    
    // RZ decoder logic would be implemented here
    // with proper AXI-Stream handshaking for the decoded output
endmodule