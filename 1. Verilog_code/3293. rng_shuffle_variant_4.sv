//SystemVerilog
module rng_shuffle_13_axi_stream (
    input              clk,
    input              rst,
    // AXI-Stream slave interface (input handshake)
    input              s_axis_tvalid,
    output             s_axis_tready,
    // AXI-Stream master interface (output handshake)
    output reg         m_axis_tvalid,
    input              m_axis_tready,
    output reg [7:0]   m_axis_tdata,
    output reg         m_axis_tlast
);

    // Original registers
    reg [7:0] rand_reg_main;
    reg       en_reg_main;
    reg       m_axis_tlast_main;

    // First-level buffers for high fanout signals
    reg [7:0] rand_reg_buf1;
    reg       en_reg_buf1;
    reg       m_axis_tlast_buf1;

    // Second-level buffers for further fanout reduction (if required)
    reg [7:0] rand_reg_buf2;
    reg       en_reg_buf2;
    reg       m_axis_tlast_buf2;

    // Control AXI-Stream ready with buffered enable
    assign s_axis_tready = !en_reg_buf2;

    always @(posedge clk) begin
        if (rst) begin
            rand_reg_main     <= 8'hC3;
            en_reg_main       <= 1'b0;
            m_axis_tvalid     <= 1'b0;
            m_axis_tdata      <= 8'd0;
            m_axis_tlast_main <= 1'b0;

            // Clear buffers on reset
            rand_reg_buf1     <= 8'hC3;
            rand_reg_buf2     <= 8'hC3;
            en_reg_buf1       <= 1'b0;
            en_reg_buf2       <= 1'b0;
            m_axis_tlast_buf1 <= 1'b0;
            m_axis_tlast_buf2 <= 1'b0;
        end else begin
            // Input handshake: latch enable when s_axis_tvalid & s_axis_tready
            if (s_axis_tvalid && !en_reg_buf2) begin
                en_reg_main <= 1'b1;
            end else if (en_reg_buf2 && m_axis_tvalid && m_axis_tready) begin
                en_reg_main <= 1'b0;
            end

            // Data processing and AXI-Stream output
            if (en_reg_buf2 && !m_axis_tvalid) begin
                rand_reg_main     <= {rand_reg_buf2[3:0], rand_reg_buf2[7:4]} ^ {4'h9, 4'h6};
                m_axis_tdata      <= {rand_reg_buf2[3:0], rand_reg_buf2[7:4]} ^ {4'h9, 4'h6};
                m_axis_tvalid     <= 1'b1;
                m_axis_tlast_main <= 1'b1; // Single-beat transaction
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid     <= 1'b0;
                m_axis_tlast_main <= 1'b0;
            end

            // Buffering for high fanout signals: rand_reg
            rand_reg_buf1 <= rand_reg_main;
            rand_reg_buf2 <= rand_reg_buf1;

            // Buffering for high fanout signals: en_reg
            en_reg_buf1 <= en_reg_main;
            en_reg_buf2 <= en_reg_buf1;

            // Buffering for high fanout signals: m_axis_tlast
            m_axis_tlast_buf1 <= m_axis_tlast_main;
            m_axis_tlast_buf2 <= m_axis_tlast_buf1;

            // Output assignment via final buffer
            m_axis_tlast <= m_axis_tlast_buf2;
        end
    end

endmodule