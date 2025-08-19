//SystemVerilog
module sync_reset_multi_enable(
    // Clock and reset
    input  wire        clk,
    input  wire        reset_in,
    
    // AXI-Stream input interface
    input  wire [3:0]  s_axis_tdata,   // 替代 enable_conditions
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    
    // AXI-Stream output interface
    output reg  [3:0]  m_axis_tdata,   // 替代 reset_out
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg         m_axis_tlast
);

    // Internal signals
    reg [3:0] reset_out_reg;
    reg       data_valid;
    wire      handshake_in;
    wire      handshake_out;
    
    // Buffered signals for high fanout nets
    reg [3:0] s_axis_tdata_buf1, s_axis_tdata_buf2;
    reg [3:0] reset_out_reg_buf1, reset_out_reg_buf2;
    reg       reset_in_buf;
    
    // Handshake signals
    assign s_axis_tready = !reset_in_buf && m_axis_tready;  // 准备接收新数据
    assign handshake_in = s_axis_tvalid && s_axis_tready;
    assign handshake_out = m_axis_tvalid && m_axis_tready;
    
    // Input data buffering to reduce fanout
    always @(posedge clk) begin
        s_axis_tdata_buf1 <= s_axis_tdata;
        s_axis_tdata_buf2 <= s_axis_tdata_buf1;
        reset_in_buf <= reset_in;
    end
    
    // Reset_out_reg buffering to reduce fanout
    always @(posedge clk) begin
        reset_out_reg_buf1 <= reset_out_reg;
        reset_out_reg_buf2 <= reset_out_reg_buf1;
    end
    
    // Main processing logic
    always @(posedge clk) begin
        if (reset_in_buf) begin
            reset_out_reg <= 4'b1111;
            data_valid <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
        end
        else begin
            // Process data when valid handshake occurs
            if (handshake_in) begin
                reset_out_reg[0] <= s_axis_tdata_buf2[0] ? 1'b0 : reset_out_reg[0];
                reset_out_reg[1] <= s_axis_tdata_buf2[1] ? 1'b0 : reset_out_reg[1];
                reset_out_reg[2] <= s_axis_tdata_buf2[2] ? 1'b0 : reset_out_reg[2];
                reset_out_reg[3] <= s_axis_tdata_buf2[3] ? 1'b0 : reset_out_reg[3];
                data_valid <= 1'b1;
            end
            
            // Handle output interface
            if (data_valid && !m_axis_tvalid) begin
                m_axis_tdata <= reset_out_reg_buf2;
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= 1'b1;  // 标记为传输的最后一个数据
            end
            else if (handshake_out) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
                data_valid <= 1'b0;
            end
        end
    end

endmodule