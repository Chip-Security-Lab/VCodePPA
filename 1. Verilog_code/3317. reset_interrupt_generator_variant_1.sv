//SystemVerilog
module reset_interrupt_generator_axi_stream (
  input               clk,
  input               rst_n,
  input       [5:0]   reset_sources,      // Active high
  input       [5:0]   interrupt_mask,     // 1=generate interrupt
  input               s_axis_tvalid,      // AXI-Stream TVALID (input handshake)
  output              s_axis_tready,      // AXI-Stream TREADY (input handshake)
  input               interrupt_ack,
  output reg          m_axis_tvalid,      // AXI-Stream TVALID (output handshake)
  input               m_axis_tready,      // AXI-Stream TREADY (output handshake)
  output reg  [5:0]   m_axis_tdata,       // AXI-Stream TDATA (pending sources)
  output reg          m_axis_tlast        // AXI-Stream TLAST (single-beat)
);

  // Stage 1: Register input and compute new resets (splitting combinatorial logic)
  reg [5:0] reset_sources_stage1;
  reg [5:0] prev_sources_stage1;
  reg [5:0] interrupt_mask_stage1;
  reg       s_axis_tvalid_stage1;
  reg       interrupt_ack_stage1;

  // Stage 2: Compute new_resets, pending_sources update
  reg [5:0] prev_sources_stage2;
  reg [5:0] pending_sources_stage2;
  reg [5:0] new_resets_stage2;
  reg       interrupt_pending_stage2;
  reg       s_axis_tvalid_stage2;
  reg       interrupt_ack_stage2;

  // Stage 3: Prepare AXI output signals
  reg [5:0] pending_sources_stage3;
  reg [5:0] new_resets_stage3;
  reg       interrupt_pending_stage3;
  reg       interrupt_ack_stage3;

  // Stage 4: AXI output handshake and final output registers
  reg       m_axis_tvalid_stage4;
  reg [5:0] m_axis_tdata_stage4;
  reg       m_axis_tlast_stage4;

  // Always ready to accept input
  assign s_axis_tready = 1'b1;

  // Stage 1: Register inputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reset_sources_stage1     <= 6'h00;
      prev_sources_stage1      <= 6'h00;
      interrupt_mask_stage1    <= 6'h00;
      s_axis_tvalid_stage1     <= 1'b0;
      interrupt_ack_stage1     <= 1'b0;
    end else begin
      reset_sources_stage1     <= reset_sources;
      prev_sources_stage1      <= prev_sources_stage2;
      interrupt_mask_stage1    <= interrupt_mask;
      s_axis_tvalid_stage1     <= s_axis_tvalid;
      interrupt_ack_stage1     <= interrupt_ack;
    end
  end

  // Stage 2: Detect new resets, update pending_sources and interrupt_pending
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_sources_stage2      <= 6'h00;
      pending_sources_stage2   <= 6'h00;
      new_resets_stage2        <= 6'h00;
      interrupt_pending_stage2 <= 1'b0;
      s_axis_tvalid_stage2     <= 1'b0;
      interrupt_ack_stage2     <= 1'b0;
    end else begin
      // Compute new resets
      new_resets_stage2 <= (reset_sources_stage1 & ~prev_sources_stage1) & interrupt_mask_stage1;
      // Sample input and update pending_sources
      if (s_axis_tvalid_stage1 && s_axis_tready) begin
        prev_sources_stage2      <= reset_sources_stage1;
        if (interrupt_ack_stage1) begin
          pending_sources_stage2   <= 6'h00;
        end else begin
          pending_sources_stage2   <= pending_sources_stage2 | ((reset_sources_stage1 & ~prev_sources_stage1) & interrupt_mask_stage1);
        end
        interrupt_pending_stage2 <= |(pending_sources_stage2 | ((reset_sources_stage1 & ~prev_sources_stage1) & interrupt_mask_stage1));
      end else if (interrupt_ack_stage1) begin
        pending_sources_stage2   <= 6'h00;
        interrupt_pending_stage2 <= 1'b0;
      end
      s_axis_tvalid_stage2     <= s_axis_tvalid_stage1;
      interrupt_ack_stage2     <= interrupt_ack_stage1;
    end
  end

  // Stage 3: Prepare for AXI output
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending_sources_stage3    <= 6'h00;
      new_resets_stage3         <= 6'h00;
      interrupt_pending_stage3  <= 1'b0;
      interrupt_ack_stage3      <= 1'b0;
    end else begin
      pending_sources_stage3    <= pending_sources_stage2;
      new_resets_stage3         <= new_resets_stage2;
      interrupt_pending_stage3  <= interrupt_pending_stage2;
      interrupt_ack_stage3      <= interrupt_ack_stage2;
    end
  end

  // Stage 4: AXI output handshake and output registers
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m_axis_tvalid_stage4      <= 1'b0;
      m_axis_tdata_stage4       <= 6'h00;
      m_axis_tlast_stage4       <= 1'b0;
    end else begin
      // Output a single-beat stream when interrupt_pending is asserted and not already sent
      if (interrupt_pending_stage3 && !m_axis_tvalid_stage4) begin
        m_axis_tvalid_stage4    <= 1'b1;
        m_axis_tdata_stage4     <= pending_sources_stage3 | new_resets_stage3;
        m_axis_tlast_stage4     <= 1'b1;
      end else if (m_axis_tvalid_stage4 && m_axis_tready) begin
        m_axis_tvalid_stage4    <= 1'b0;
        m_axis_tlast_stage4     <= 1'b0;
      end
    end
  end

  // Output assignments
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m_axis_tvalid <= 1'b0;
      m_axis_tdata  <= 6'h00;
      m_axis_tlast  <= 1'b0;
    end else begin
      m_axis_tvalid <= m_axis_tvalid_stage4;
      m_axis_tdata  <= m_axis_tdata_stage4;
      m_axis_tlast  <= m_axis_tlast_stage4;
    end
  end

endmodule