//SystemVerilog
module rgb888_to_rgb444_codec (
    input wire clk,                 // Clock
    input wire rst,                 // Reset
    
    // AXI-Stream Input Interface
    input wire [23:0] s_axis_tdata, // RGB888 input data
    input wire s_axis_tvalid,       // Input valid signal
    input wire s_axis_tlast,        // Input last signal (passing through)
    output wire s_axis_tready,      // Ready to accept input
    
    // Configuration inputs
    input wire dither_en,           // Dither enable
    input wire [3:0] dither_seed,   // Dither seed
    
    // AXI-Stream Output Interface
    output wire [11:0] m_axis_tdata, // RGB444 output data
    output reg m_axis_tvalid,        // Output valid signal
    output reg m_axis_tlast,         // Output last signal
    input wire m_axis_tready         // Downstream ready signal
);

    // Internal registers
    reg [3:0] lfsr;
    wire dither_bit;
    reg [11:0] rgb444_out_reg;
    
    // Processing state
    reg processing_data;
    
    // Buffer registers for high fan-out signals
    reg [23:0] s_axis_tdata_buf1, s_axis_tdata_buf2;
    reg dither_en_buf1, dither_en_buf2;
    reg [3:0] lfsr_buf1, lfsr_buf2;
    reg dither_bit_buf1, dither_bit_buf2;
    reg [11:0] rgb444_out_reg_buf;
    
    // Generate ready signal - we're ready when downstream is ready or we're not processing
    assign s_axis_tready = m_axis_tready || !m_axis_tvalid;
    
    // Assign output data through buffered signal
    assign m_axis_tdata = rgb444_out_reg_buf;
    
    // Buffer high fan-out signals
    always @(posedge clk) begin
        if (rst) begin
            s_axis_tdata_buf1 <= 24'h0;
            s_axis_tdata_buf2 <= 24'h0;
            dither_en_buf1 <= 1'b0;
            dither_en_buf2 <= 1'b0;
            lfsr_buf1 <= 4'h0;
            lfsr_buf2 <= 4'h0;
            dither_bit_buf1 <= 1'b0;
            dither_bit_buf2 <= 1'b0;
            rgb444_out_reg_buf <= 12'h0;
        end
        else begin
            // Multi-stage buffering for s_axis_tdata
            s_axis_tdata_buf1 <= s_axis_tdata;
            s_axis_tdata_buf2 <= s_axis_tdata_buf1;
            
            // Buffer dither enable
            dither_en_buf1 <= dither_en;
            dither_en_buf2 <= dither_en_buf1;
            
            // Buffer LFSR value
            lfsr_buf1 <= lfsr;
            lfsr_buf2 <= lfsr_buf1;
            
            // Buffer dither bit
            dither_bit_buf1 <= dither_bit;
            dither_bit_buf2 <= dither_bit_buf1;
            
            // Buffer output register
            rgb444_out_reg_buf <= rgb444_out_reg;
        end
    end
    
    // LFSR for dithering with improved initialization
    always @(posedge clk) begin
        if (rst)
            lfsr <= dither_seed;
        else if (dither_en_buf1 && s_axis_tvalid && s_axis_tready)
            lfsr <= {lfsr[2:0], lfsr[3] ^ lfsr[2]};
    end
    
    assign dither_bit = lfsr[0];
    
    // Data processing logic with balanced fan-out
    always @(posedge clk) begin
        if (rst) begin
            rgb444_out_reg <= 12'h000;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            processing_data <= 1'b0;
        end
        else begin
            // Start new data processing when input is valid and we're ready
            if (s_axis_tvalid && s_axis_tready) begin
                // Use buffered signals to reduce fan-out load
                // Extract most significant 4 bits from each color component
                // Add dither if enabled (1 LSB adjustment)
                rgb444_out_reg[11:8] <= s_axis_tdata_buf1[23:20] + 
                                        (dither_en_buf1 & dither_bit_buf1 & (s_axis_tdata_buf1[19:16] > 4'h8));
                rgb444_out_reg[7:4] <= s_axis_tdata_buf1[15:12] + 
                                       (dither_en_buf1 & dither_bit_buf1 & (s_axis_tdata_buf1[11:8] > 4'h8));
                rgb444_out_reg[3:0] <= s_axis_tdata_buf1[7:4] + 
                                       (dither_en_buf1 & dither_bit_buf1 & (s_axis_tdata_buf1[3:0] > 4'h8));
                
                // Set valid and last signals
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= s_axis_tlast;
                processing_data <= 1'b1;
            end
            // Clear valid when transfer completes
            else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
                processing_data <= 1'b0;
            end
        end
    end

endmodule