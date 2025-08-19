//SystemVerilog
module rng_fib_lfsr_axi_stream (
    input              clk,
    input              rst,
    // AXI-Stream Slave Side (input handshake)
    input              s_axis_tready,
    input              s_axis_tvalid,
    // AXI-Stream Master Side (output handshake)
    output reg         m_axis_tvalid,
    input              m_axis_tready,
    output reg [7:0]   m_axis_tdata,
    output reg         m_axis_tlast
);

    // Internal enable based on input handshake
    wire stream_en = s_axis_tvalid && s_axis_tready;

    // LFSR pipeline stages
    reg [7:0] lfsr_stage1;
    reg       feedback_stage2;
    reg [7:0] lfsr_stage3;

    // AXI-Stream output data valid register
    reg [7:0] rand_latched;
    reg       data_pending;

    // Stage 1: LFSR register initialization and shifting
    always @(posedge clk) begin
        if (rst)
            lfsr_stage1 <= 8'hA5;
        else if (stream_en)
            lfsr_stage1 <= lfsr_stage3;
    end

    // Stage 2: Feedback calculation (combinational, registered for pipelining)
    always @(posedge clk) begin
        if (rst)
            feedback_stage2 <= ^(8'hA5 & 8'b10110100);
        else
            feedback_stage2 <= ^(lfsr_stage1 & 8'b10110100);
    end

    // Stage 3: LFSR update logic (combinational, registered for pipelining)
    always @(posedge clk) begin
        if (rst)
            lfsr_stage3 <= 8'hA5;
        else
            lfsr_stage3 <= {lfsr_stage1[6:0], feedback_stage2};
    end

    // Output data latch and valid control for AXI-Stream
    always @(posedge clk) begin
        if (rst) begin
            rand_latched    <= 8'hA5;
            m_axis_tvalid   <= 1'b0;
            m_axis_tdata    <= 8'hA5;
            m_axis_tlast    <= 1'b0;
            data_pending    <= 1'b0;
        end else begin
            // Data generation and latch when input handshake is valid
            if (stream_en) begin
                rand_latched  <= lfsr_stage3;
                data_pending  <= 1'b1;
            end

            // Output handshake: present data when valid and ready
            if (data_pending && (!m_axis_tvalid || (m_axis_tvalid && m_axis_tready))) begin
                m_axis_tdata  <= rand_latched;
                m_axis_tvalid <= 1'b1;
                m_axis_tlast  <= 1'b0; // Set to 1'b1 if required for packetization
                data_pending  <= 1'b0;
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end

endmodule