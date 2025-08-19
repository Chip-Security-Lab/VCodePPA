//SystemVerilog
module ResetSynchronizer_AXIStream (
    input  wire        aclk,
    input  wire        aresetn,
    output wire [0:0]  m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast
);

    reg rst_ff1_reg;
    reg rst_sync_reg;
    reg rst_sync_buf;
    reg data_valid_reg;
    reg data_valid_buf;
    reg data_sent_reg;
    reg m_axis_tvalid_buf;
    reg b0_reg;
    reg b0_buf;

    // Synchronizer and buffer logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rst_ff1_reg      <= 1'b0;
            rst_sync_reg     <= 1'b0;
            rst_sync_buf     <= 1'b0;
            data_valid_reg   <= 1'b0;
            data_valid_buf   <= 1'b0;
            data_sent_reg    <= 1'b0;
            m_axis_tvalid_buf<= 1'b0;
            b0_reg           <= 1'b0;
            b0_buf           <= 1'b0;
        end else begin
            rst_ff1_reg      <= 1'b1;
            rst_sync_reg     <= rst_ff1_reg;
            rst_sync_buf     <= rst_sync_reg;

            if (!data_sent_reg) begin
                data_valid_reg <= 1'b1;
            end else if (m_axis_tvalid_buf && m_axis_tready) begin
                data_valid_reg <= 1'b0;
            end

            if (m_axis_tvalid_buf && m_axis_tready) begin
                data_sent_reg <= 1'b1;
            end

            data_valid_buf    <= data_valid_reg;
            m_axis_tvalid_buf <= data_valid_reg;
            b0_reg            <= data_valid_reg;
            b0_buf            <= b0_reg;
        end
    end

    assign m_axis_tdata  = rst_sync_buf;
    assign m_axis_tvalid = m_axis_tvalid_buf;
    assign m_axis_tlast  = b0_buf;

endmodule