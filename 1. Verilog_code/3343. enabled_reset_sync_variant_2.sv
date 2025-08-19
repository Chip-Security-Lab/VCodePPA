//SystemVerilog
module enabled_reset_sync_axi_stream (
    input  wire         aclk,
    input  wire         aresetn,
    input  wire         s_axis_tvalid,
    input  wire [0:0]   s_axis_tdata,   // 1-bit enable signal mapped to TDATA
    output wire         s_axis_tready,
    output reg          m_axis_tvalid,
    output reg  [0:0]   m_axis_tdata,   // 1-bit rst_out_n mapped to TDATA
    input  wire         m_axis_tready
);

    reg metastable_reg;
    reg enable_reg;
    // Buffering the high fanout signal 'b0' (s_axis_tdata[0]) with a two-level register tree
    reg b0_buf_level1;
    reg b0_buf_level2;

    assign s_axis_tready = (m_axis_tready || !m_axis_tvalid);

    // Buffer 'b0' (s_axis_tdata[0]) with register stages to reduce fanout and balance load
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            b0_buf_level1 <= 1'b0;
            b0_buf_level2 <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                b0_buf_level1 <= s_axis_tdata[0];
            end
            b0_buf_level2 <= b0_buf_level1;
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            metastable_reg <= 1'b0;
            m_axis_tvalid  <= 1'b0;
            m_axis_tdata   <= 1'b0;
            enable_reg     <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                enable_reg <= b0_buf_level2;
                if (b0_buf_level2) begin
                    metastable_reg <= 1'b1;
                end
            end

            if (s_axis_tvalid && s_axis_tready && enable_reg) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tdata  <= metastable_reg;
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end

endmodule