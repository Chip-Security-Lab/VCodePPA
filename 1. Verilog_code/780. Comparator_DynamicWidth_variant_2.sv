//SystemVerilog
module Comparator_DynamicWidth (
    // AXI-Stream input interface for data_x
    input         [15:0]  s_axis_x_tdata,
    input                 s_axis_x_tvalid,
    output reg            s_axis_x_tready,
    
    // AXI-Stream input interface for data_y
    input         [15:0]  s_axis_y_tdata,
    input                 s_axis_y_tvalid,
    output reg            s_axis_y_tready,
    
    // AXI-Stream input interface for valid_bits
    input         [3:0]   s_axis_config_tdata,
    input                 s_axis_config_tvalid,
    output reg            s_axis_config_tready,
    
    // AXI-Stream output interface
    output reg    [0:0]   m_axis_result_tdata,  // unequal result
    output reg            m_axis_result_tvalid,
    input                 m_axis_result_tready,
    
    // Clock and reset
    input                 aclk,
    input                 aresetn
);

    // Internal registers
    reg [15:0] data_x_reg;
    reg [15:0] data_y_reg;
    reg [3:0]  valid_bits_reg;
    reg        data_ready;
    reg        result_valid;
    
    // Comparison result
    wire [15:0] mask;
    wire unequal_result;
    
    // Generate dynamic mask based on valid_bits
    assign mask = (16'hFFFF << valid_bits_reg);
    assign unequal_result = ((data_x_reg & ~mask) != (data_y_reg & ~mask));
    
    // Input handshaking logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axis_x_tready <= 1'b0;
            s_axis_y_tready <= 1'b0;
            s_axis_config_tready <= 1'b0;
            data_x_reg <= 16'b0;
            data_y_reg <= 16'b0;
            valid_bits_reg <= 4'b0;
            data_ready <= 1'b0;
        end else begin
            // Default ready signals
            s_axis_x_tready <= !data_ready || m_axis_result_tready;
            s_axis_y_tready <= !data_ready || m_axis_result_tready;
            s_axis_config_tready <= !data_ready || m_axis_result_tready;
            
            // Capture input data when valid
            if (s_axis_x_tvalid && s_axis_x_tready)
                data_x_reg <= s_axis_x_tdata;
                
            if (s_axis_y_tvalid && s_axis_y_tready)
                data_y_reg <= s_axis_y_tdata;
                
            if (s_axis_config_tvalid && s_axis_config_tready)
                valid_bits_reg <= s_axis_config_tdata;
            
            // Set data_ready when all inputs are received
            if (s_axis_x_tvalid && s_axis_y_tvalid && s_axis_config_tvalid &&
                s_axis_x_tready && s_axis_y_tready && s_axis_config_tready)
                data_ready <= 1'b1;
                
            // Clear data_ready when result is transferred
            if (data_ready && m_axis_result_tvalid && m_axis_result_tready)
                data_ready <= 1'b0;
        end
    end
    
    // Output handshaking logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axis_result_tvalid <= 1'b0;
            m_axis_result_tdata <= 1'b0;
        end else begin
            // Set valid when data is ready
            if (data_ready && !m_axis_result_tvalid)
                m_axis_result_tvalid <= 1'b1;
                
            // Update output data
            if (data_ready && (!m_axis_result_tvalid || m_axis_result_tready))
                m_axis_result_tdata <= unequal_result;
                
            // Clear valid when handshake completes
            if (m_axis_result_tvalid && m_axis_result_tready)
                m_axis_result_tvalid <= 1'b0;
        end
    end

endmodule