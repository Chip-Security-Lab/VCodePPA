//SystemVerilog
module adaptive_contrast_codec (
    input wire clk,
    input wire rst_n,
    
    // Input AXI-Stream interface
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tvalid,
    input wire s_axis_tlast,  // Indicates end of frame
    output wire s_axis_tready,
    
    // Control inputs
    input wire [7:0] min_val, max_val,  // Current frame min/max values
    input wire enable,
    
    // Output AXI-Stream interface
    output wire [7:0] m_axis_tdata,
    output reg m_axis_tvalid,
    output reg m_axis_tlast,
    input wire m_axis_tready
);
    // Contrast range registers
    reg [7:0] contrast_min, contrast_max;
    
    // Registered copies with reduced fanout
    reg [7:0] contrast_min_buf1, contrast_min_buf2;
    reg [7:0] contrast_max_buf1, contrast_max_buf2;
    
    // Calculate range using buffered values
    wire [8:0] range = contrast_max_buf1 - contrast_min_buf1;
    
    // Use registered version of range to reduce fanout
    reg [8:0] range_reg;
    
    // Division operand with reduced fanout
    wire [8:0] div_operand = (range_reg == 0) ? 9'd1 : range_reg;
    
    // Pipeline registers and calculation stages
    reg [7:0] pixel_in_reg;
    reg [7:0] pixel_diff;     // pixel_in - contrast_min
    reg [16:0] mult_result;   // pixel_diff * 255
    wire [16:0] scaled_pixel = mult_result / div_operand;
    
    // Enable signal buffering
    reg enable_buf1, enable_buf2;
    
    // AXI-Stream flow control registers
    reg [7:0] pixel_out_reg;
    reg pixel_valid_reg;
    reg tlast_pipe1, tlast_pipe2, tlast_pipe3;
    
    // Processing state machine
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam OUTPUT_READY = 2'b10;
    
    // Ready signal generation
    assign s_axis_tready = (state == IDLE) || ((state == PROCESSING) && m_axis_tready);
    
    // Output data assignment
    assign m_axis_tdata = pixel_out_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            contrast_min <= 8'd0;
            contrast_max <= 8'd255;
            contrast_min_buf1 <= 8'd0;
            contrast_min_buf2 <= 8'd0;
            contrast_max_buf1 <= 8'd255;
            contrast_max_buf2 <= 8'd255;
            range_reg <= 9'd255;
            pixel_out_reg <= 8'd0;
            pixel_in_reg <= 8'd0;
            pixel_diff <= 8'd0;
            mult_result <= 17'd0;
            enable_buf1 <= 1'b0;
            enable_buf2 <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            tlast_pipe1 <= 1'b0;
            tlast_pipe2 <= 1'b0;
            tlast_pipe3 <= 1'b0;
            state <= IDLE;
            pixel_valid_reg <= 1'b0;
        end else begin
            // Update contrast range on frame boundary
            if (s_axis_tvalid && s_axis_tlast && s_axis_tready) begin
                contrast_min <= min_val;
                contrast_max <= max_val;
            end
            
            // Buffer stage for high fanout signals
            contrast_min_buf1 <= contrast_min;
            contrast_min_buf2 <= contrast_min_buf1;
            contrast_max_buf1 <= contrast_max;
            contrast_max_buf2 <= contrast_max_buf1;
            range_reg <= range;
            
            // Buffer enable signal
            enable_buf1 <= enable;
            enable_buf2 <= enable_buf1;
            
            // Pipeline tlast signal
            if (s_axis_tvalid && s_axis_tready) begin
                tlast_pipe1 <= s_axis_tlast;
            end
            tlast_pipe2 <= tlast_pipe1;
            tlast_pipe3 <= tlast_pipe2;
            
            // State machine & data processing
            case (state)
                IDLE: begin
                    m_axis_tvalid <= 1'b0;
                    if (s_axis_tvalid && s_axis_tready) begin
                        pixel_in_reg <= s_axis_tdata;
                        state <= PROCESSING;
                    end
                end
                
                PROCESSING: begin
                    // Pipeline stages for calculation
                    pixel_diff <= pixel_in_reg - contrast_min_buf2;
                    mult_result <= pixel_diff * 17'd255;
                    
                    // Apply contrast stretching if enabled
                    if (enable_buf2)
                        pixel_out_reg <= (scaled_pixel > 255) ? 8'd255 : scaled_pixel[7:0];
                    else
                        pixel_out_reg <= pixel_in_reg;
                    
                    m_axis_tvalid <= 1'b1;
                    m_axis_tlast <= tlast_pipe3;
                    
                    if (m_axis_tready) begin
                        if (s_axis_tvalid) begin
                            // Accept new data immediately
                            pixel_in_reg <= s_axis_tdata;
                            state <= PROCESSING;
                        end else begin
                            // No new data, return to IDLE
                            state <= IDLE;
                            m_axis_tvalid <= 1'b0;
                        end
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule