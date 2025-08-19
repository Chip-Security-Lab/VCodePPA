//SystemVerilog
module multi_io_ctrl (
    input  wire        aclk,           // System clock
    input  wire        aresetn,        // Active low reset
    
    // AXI-Stream Slave Interface
    input  wire        s_axis_tvalid,  // Input data valid
    output wire        s_axis_tready,  // Ready to accept data
    input  wire [7:0]  s_axis_tdata,   // Input data
    input  wire        s_axis_tlast,   // End of packet signal
    
    // AXI-Stream Master Interface
    output wire        m_axis_tvalid,  // Output data valid
    input  wire        m_axis_tready,  // Downstream ready
    output wire [7:0]  m_axis_tdata,   // Output data
    output wire        m_axis_tlast,   // End of packet signal
    
    // Mode select and control outputs
    input  wire        mode_sel,       // Mode selection: 1=I2C mode, 0=SPI mode
    output wire        scl,            // I2C clock line
    output wire        sda,            // I2C data line
    output wire        spi_cs          // SPI chip select signal
);

    // Internal registers
    reg scl_reg;
    reg sda_reg;
    reg spi_cs_reg;
    
    // Data and control registers
    reg data_bit_i2c;
    reg i2c_mode;
    reg spi_mode;
    reg [1:0] control_state;
    
    // AXI-Stream control registers
    reg s_tready_reg;
    reg m_tvalid_reg;
    reg [7:0] m_tdata_reg;
    reg m_tlast_reg;
    
    // Data capture and processing state
    reg data_processed;
    reg [2:0] processing_state;
    
    // Handshaking and flow control
    assign s_axis_tready = s_tready_reg;
    assign m_axis_tvalid = m_tvalid_reg;
    assign m_axis_tdata = m_tdata_reg;
    assign m_axis_tlast = m_tlast_reg;
    
    // Output assignments
    assign scl = scl_reg;
    assign sda = sda_reg;
    assign spi_cs = spi_cs_reg;
    
    // Reset and initialization logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            // Reset values
            scl_reg <= 1'b1;
            sda_reg <= 1'b1;
            spi_cs_reg <= 1'b1;
            data_bit_i2c <= 1'b0;
            i2c_mode <= 1'b0;
            spi_mode <= 1'b0;
            control_state <= 2'b00;
            s_tready_reg <= 1'b1;
            m_tvalid_reg <= 1'b0;
            m_tdata_reg <= 8'h00;
            m_tlast_reg <= 1'b0;
            data_processed <= 1'b0;
            processing_state <= 3'b000;
        end
        else begin
            // Default state for next cycle
            s_tready_reg <= 1'b1; // Ready to accept new data by default
            
            // Input data handling with AXI handshaking
            if (s_axis_tvalid && s_tready_reg) begin
                // Capture data and signals when valid data is presented
                data_bit_i2c <= s_axis_tdata[7];
                i2c_mode <= mode_sel;
                spi_mode <= ~mode_sel;
                data_processed <= 1'b1;
                
                // For pass-through functionality
                m_tdata_reg <= s_axis_tdata;
                m_tlast_reg <= s_axis_tlast;
                m_tvalid_reg <= 1'b1;
                
                // Update processing state
                processing_state <= 3'b001;
            end
            
            // Output data handling with AXI handshaking
            if (m_tvalid_reg && m_axis_tready) begin
                m_tvalid_reg <= 1'b0; // Clear valid after data accepted
            end
            
            // I2C/SPI protocol handling logic
            if (data_processed) begin
                case (processing_state)
                    3'b001: begin
                        // I2C mode control
                        if (i2c_mode) begin
                            control_state <= {scl_reg, 1'b0};
                            processing_state <= 3'b010;
                        end
                        // SPI mode control
                        else if (spi_mode) begin
                            spi_cs_reg <= s_axis_tdata[0];
                            data_processed <= 1'b0;
                            processing_state <= 3'b000;
                        end
                    end
                    
                    3'b010: begin
                        // I2C clock generation
                        scl_reg <= ~control_state[1];
                        sda_reg <= data_bit_i2c;
                        data_processed <= 1'b0;
                        processing_state <= 3'b000;
                    end
                    
                    default: begin
                        processing_state <= 3'b000;
                    end
                endcase
            end
        end
    end
    
endmodule