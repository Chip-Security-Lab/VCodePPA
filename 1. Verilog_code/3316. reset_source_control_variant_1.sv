//SystemVerilog
module reset_source_control_axi_stream (
  input  wire        clk,
  input  wire        master_rst_n,
  input  wire [7:0]  reset_sources,   // Active high reset signals
  input  wire [7:0]  enable_mask,     // 1=enabled, 0=disabled
  // AXI-Stream output interface
  output reg  [7:0]  m_axis_tdata,
  output reg         m_axis_tvalid,
  input  wire        m_axis_tready,
  output reg         m_axis_tlast,
  output reg         system_reset
);

  // Internal registers for buffering high fanout signals
  reg [7:0] masked_sources_reg, masked_sources_next;
  reg       valid_reg, valid_next;
  reg       tlast_reg, tlast_next;
  reg       system_reset_reg, system_reset_next;

  // 1st stage buffer registers for high fanout signals
  reg [7:0] masked_sources_buf1;
  reg       valid_buf1;
  reg       tlast_buf1;

  // 2nd stage buffer registers for high fanout signals
  reg [7:0] masked_sources_buf2;
  reg       valid_buf2;
  reg       tlast_buf2;

  // AXI output buffer registers
  reg       m_axis_tvalid_buf;
  reg [7:0] m_axis_tdata_buf;
  reg       m_axis_tlast_buf;

  wire [7:0] masked_sources = reset_sources & enable_mask;

  // Combinational logic for next-state calculation
  always @(*) begin
    masked_sources_next = masked_sources_reg;
    valid_next          = valid_reg;
    tlast_next          = tlast_reg;
    system_reset_next   = system_reset_reg;

    if (masked_sources != masked_sources_reg) begin
      masked_sources_next = masked_sources;
      valid_next          = 1'b1;
      tlast_next          = 1'b1;
      system_reset_next   = |masked_sources;
    end else if (valid_reg && m_axis_tready) begin
      valid_next          = 1'b0;
      tlast_next          = 1'b0;
    end
  end

  // Sequential logic with multi-stage buffering for critical signals
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n) begin
      masked_sources_reg   <= 8'h00;
      masked_sources_buf1  <= 8'h00;
      masked_sources_buf2  <= 8'h00;
      valid_reg            <= 1'b0;
      valid_buf1           <= 1'b0;
      valid_buf2           <= 1'b0;
      tlast_reg            <= 1'b0;
      tlast_buf1           <= 1'b0;
      tlast_buf2           <= 1'b0;
      m_axis_tdata_buf     <= 8'h00;
      m_axis_tvalid_buf    <= 1'b0;
      m_axis_tlast_buf     <= 1'b0;
      m_axis_tdata         <= 8'h00;
      m_axis_tvalid        <= 1'b0;
      m_axis_tlast         <= 1'b0;
      system_reset_reg     <= 1'b0;
      system_reset         <= 1'b0;
    end else begin
      // Pipeline stage 1: Update core registers
      masked_sources_reg   <= masked_sources_next;
      valid_reg            <= valid_next;
      tlast_reg            <= tlast_next;
      system_reset_reg     <= system_reset_next;

      // Pipeline stage 2: Buffer high fanout signals (stage 1)
      masked_sources_buf1  <= masked_sources_reg;
      valid_buf1           <= valid_reg;
      tlast_buf1           <= tlast_reg;

      // Pipeline stage 3: Buffer high fanout signals (stage 2)
      masked_sources_buf2  <= masked_sources_buf1;
      valid_buf2           <= valid_buf1;
      tlast_buf2           <= tlast_buf1;

      // Output buffer registers for AXI signals
      m_axis_tdata_buf     <= masked_sources_buf2;
      m_axis_tvalid_buf    <= valid_buf2;
      m_axis_tlast_buf     <= tlast_buf2;

      // Final output assignment
      m_axis_tdata         <= m_axis_tdata_buf;
      m_axis_tvalid        <= m_axis_tvalid_buf;
      m_axis_tlast         <= m_axis_tlast_buf;
      system_reset         <= system_reset_reg;
    end
  end

endmodule