//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 Verilog standard
module barrel_shifter_axi_stream (
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream slave interface
    input wire [7:0] s_axis_tdata,
    input wire [2:0] s_axis_tuser,  // Using tuser for shift_amount
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // AXI-Stream master interface
    output wire [7:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready
);

    // Enhanced pipeline registers
    reg [7:0] data_out_reg;
    reg m_valid_reg;
    reg s_ready_reg;
    
    // Buffered signals to reduce fanout
    reg [7:0] s_axis_tdata_buf;
    reg [2:0] s_axis_tuser_buf;
    
    // Additional buffer registers for left and right shift operations
    reg [7:0] left_shift_buf1, left_shift_buf2;
    reg [7:0] right_shift_buf1, right_shift_buf2;
    
    // Input buffering stage for high fanout signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tdata_buf <= 8'b0;
            s_axis_tuser_buf <= 3'b0;
        end else if (transfer_in) begin
            s_axis_tdata_buf <= s_axis_tdata;
            s_axis_tuser_buf <= s_axis_tuser;
        end
    end
    
    // Pre-compute shift values with balanced load distribution
    wire [7:0] left_shift = s_axis_tdata_buf << s_axis_tuser_buf;
    wire [7:0] right_shift = s_axis_tdata_buf >> (8 - s_axis_tuser_buf);
    
    // Optimized handshaking logic
    wire transfer_in = s_axis_tvalid && s_axis_tready;
    wire transfer_out = m_axis_tvalid && m_axis_tready;
    
    // Buffer left and right shift results to reduce combinational path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_shift_buf1 <= 8'b0;
            right_shift_buf1 <= 8'b0;
        end else if (transfer_in) begin
            left_shift_buf1 <= left_shift;
            right_shift_buf1 <= right_shift;
        end
    end
    
    // Second layer of buffers to further distribute load
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_shift_buf2 <= 8'b0;
            right_shift_buf2 <= 8'b0;
        end else begin
            left_shift_buf2 <= left_shift_buf1;
            right_shift_buf2 <= right_shift_buf1;
        end
    end
    
    // Improved ready signal handling for better throughput
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_ready_reg <= 1'b1;
        end else begin
            if (transfer_out || !m_valid_reg)
                s_ready_reg <= 1'b1;
            else if (transfer_in)
                s_ready_reg <= 1'b0;
        end
    end
    
    // Optimized barrel shift logic with reduced critical path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_reg <= 8'b0;
            m_valid_reg <= 1'b0;
        end else begin
            if (transfer_in) begin
                // Use the buffered shift values to reduce critical path
                data_out_reg <= left_shift_buf2 | right_shift_buf2;
                m_valid_reg <= 1'b1;
            end else if (transfer_out) begin
                m_valid_reg <= 1'b0;
            end
        end
    end
    
    // Output assignments
    assign s_axis_tready = s_ready_reg;
    assign m_axis_tvalid = m_valid_reg;
    assign m_axis_tdata = data_out_reg;

endmodule