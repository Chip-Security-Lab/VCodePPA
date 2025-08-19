//SystemVerilog
module adaptive_contrast_codec (
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream Slave Interface
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tvalid,
    input wire s_axis_tlast,
    output wire s_axis_tready,
    
    // Additional configuration inputs
    input wire [7:0] min_val, max_val,  // Current frame min/max values
    input wire enable,
    
    // AXI-Stream Master Interface
    output wire [7:0] m_axis_tdata,
    output reg m_axis_tvalid,
    output reg m_axis_tlast,
    input wire m_axis_tready
);
    // Clock buffering for high fanout reduction
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // Clock buffer instantiation - spreading the load
    assign clk_buf1 = clk; // Clock for input stage
    assign clk_buf2 = clk; // Clock for processing stage
    assign clk_buf3 = clk; // Clock for output stage
    
    // Internal registers
    reg [7:0] contrast_min, contrast_max;
    reg [7:0] pixel_out;
    reg processing_active;
    
    // Pipeline registers for input data
    reg [7:0] s_axis_tdata_reg;
    reg s_axis_tvalid_reg, s_axis_tlast_reg;
    reg enable_reg;
    
    // Buffer for high fanout signals
    reg s_axis_tready_int;
    assign s_axis_tready = s_axis_tready_int;
    
    // Ready signal generation with reduced fanout
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tready_int <= 1'b1;
        end else begin
            s_axis_tready_int <= !m_axis_tvalid || m_axis_tready;
        end
    end
    
    // Connect output data
    assign m_axis_tdata = pixel_out;
    
    // First stage: Register inputs
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tdata_reg <= 8'd0;
            s_axis_tvalid_reg <= 1'b0;
            s_axis_tlast_reg <= 1'b0;
            enable_reg <= 1'b0;
        end else if (s_axis_tready_int) begin
            s_axis_tdata_reg <= s_axis_tdata;
            s_axis_tvalid_reg <= s_axis_tvalid;
            s_axis_tlast_reg <= s_axis_tlast;
            enable_reg <= enable;
        end
    end
    
    // Buffered versions of high fanout signals
    reg s_axis_tvalid_buf, s_axis_tready_buf;
    
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tvalid_buf <= 1'b0;
            s_axis_tready_buf <= 1'b0;
        end else begin
            s_axis_tvalid_buf <= s_axis_tvalid_reg;
            s_axis_tready_buf <= s_axis_tready_int;
        end
    end
    
    // Pre-compute the range to reduce critical path
    reg [8:0] range_reg;
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n) begin
            range_reg <= 9'd255;
        end else begin
            range_reg <= contrast_max - contrast_min;
        end
    end
    
    // Pre-compute the contrast min subtraction
    reg [8:0] pixel_shifted;
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n) begin
            pixel_shifted <= 9'd0;
        end else if (s_axis_tready_buf && s_axis_tvalid_buf) begin
            pixel_shifted <= {1'b0, s_axis_tdata_reg} - {1'b0, contrast_min};
        end
    end
    
    // Split the division operation to reduce critical path
    reg [16:0] pixel_mult;
    reg [8:0] range_reg_buf;
    
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n) begin
            pixel_mult <= 17'd0;
            range_reg_buf <= 9'd1;
        end else begin
            pixel_mult <= pixel_shifted * 255;
            range_reg_buf <= (range_reg == 0) ? 9'd1 : range_reg;
        end
    end
    
    // Final division stage
    wire [16:0] scaled_pixel = pixel_mult / range_reg_buf;
    
    always @(posedge clk_buf3 or negedge rst_n) begin
        if (!rst_n) begin
            contrast_min <= 8'd0;
            contrast_max <= 8'd255;
            pixel_out <= 8'd0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            processing_active <= 1'b0;
        end else begin
            // Handle backpressure
            if (m_axis_tready || !m_axis_tvalid) begin
                if (s_axis_tvalid_buf && s_axis_tready_buf) begin
                    // Process new data
                    processing_active <= 1'b1;
                    
                    // Update contrast range on new frame
                    if (s_axis_tlast_reg) begin
                        contrast_min <= min_val;
                        contrast_max <= max_val;
                    end
                    
                    // Apply contrast stretching if enabled
                    if (enable_reg)
                        pixel_out <= (scaled_pixel > 255) ? 8'd255 : scaled_pixel[7:0];
                    else
                        pixel_out <= s_axis_tdata_reg;
                    
                    // Set valid and propagate last signal
                    m_axis_tvalid <= 1'b1;
                    m_axis_tlast <= s_axis_tlast_reg;
                end else if (processing_active && !s_axis_tvalid_buf) begin
                    // End of processing
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast <= 1'b0;
                    processing_active <= 1'b0;
                end
            end
        end
    end
endmodule