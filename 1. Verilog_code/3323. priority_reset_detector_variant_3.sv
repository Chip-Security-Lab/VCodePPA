//SystemVerilog
module priority_reset_detector_axi_stream(
  input  wire         clk,
  input  wire         rst_n,
  input  wire         s_axis_tvalid,
  output wire         s_axis_tready,
  input  wire [7:0]   s_axis_tdata,        // reset_sources
  input  wire [23:0]  s_axis_tuser,        // priorities: [7][2:0] packed into 24 bits
  output wire         m_axis_tvalid,
  input  wire         m_axis_tready,
  output wire [13:0]  m_axis_tdata,        // {active_priority[2:0], priority_encoded[7:0], reset_out[0], reserved[2:0]}
  output wire         m_axis_tlast
);

  // Pipeline stage 1 registers
  reg [7:0] reset_sources_stage1;
  reg [7:0][2:0] priorities_stage1;
  reg           s_axis_tvalid_stage1;

  // Pipeline stage 2 registers
  reg [2:0] highest_priority_stage2;
  reg [2:0] highest_idx_stage2;
  reg [7:0] reset_sources_stage2;
  reg       s_axis_tvalid_stage2;

  integer i;
  reg [2:0] highest_priority_next;
  reg [2:0] highest_idx_next;

  // AXI-Stream handshake for input
  assign s_axis_tready = !s_axis_tvalid_stage1;

  // Unpack priorities from s_axis_tuser
  wire [7:0][2:0] priorities_unpacked;
  genvar gi;
  generate
    for (gi = 0; gi < 8; gi = gi + 1) begin : unpack
      assign priorities_unpacked[gi] = s_axis_tuser[gi*3 +: 3];
    end
  endgenerate

  // Stage 1: Register AXI-Stream inputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reset_sources_stage1   <= 8'b0;
      priorities_stage1      <= {8{3'b0}};
      s_axis_tvalid_stage1   <= 1'b0;
    end else if (s_axis_tready && s_axis_tvalid) begin
      reset_sources_stage1   <= s_axis_tdata;
      priorities_stage1      <= priorities_unpacked;
      s_axis_tvalid_stage1   <= 1'b1;
    end else if (m_axis_tvalid && m_axis_tready) begin
      s_axis_tvalid_stage1   <= 1'b0; // Clear after data accepted downstream
    end
  end

  // Stage 2: Priority calculation (combinational)
  always @(*) begin
    highest_priority_next = 3'h7;
    highest_idx_next = 3'h0;
    for (i = 0; i < 8; i = i + 1) begin
      if (reset_sources_stage1[i] && (priorities_stage1[i] < highest_priority_next)) begin
        highest_priority_next = priorities_stage1[i];
        highest_idx_next = i[2:0];
      end
    end
  end

  // Stage 2: Register calculation results
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      highest_priority_stage2 <= 3'h7;
      highest_idx_stage2      <= 3'h0;
      reset_sources_stage2    <= 8'h00;
      s_axis_tvalid_stage2    <= 1'b0;
    end else if (s_axis_tvalid_stage1) begin
      highest_priority_stage2 <= highest_priority_next;
      highest_idx_stage2      <= highest_idx_next;
      reset_sources_stage2    <= reset_sources_stage1;
      s_axis_tvalid_stage2    <= 1'b1;
    end else if (m_axis_tvalid && m_axis_tready) begin
      s_axis_tvalid_stage2    <= 1'b0;
    end
  end

  // Stage 3: Output logic and AXI-Stream handshake
  reg [2:0]  active_priority;
  reg [7:0]  priority_encoded;
  reg        reset_out;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      active_priority   <= 3'h7;
      priority_encoded  <= 8'h00;
      reset_out         <= 1'b0;
    end else if (s_axis_tvalid_stage2) begin
      if (|reset_sources_stage2) begin
        active_priority   <= highest_priority_stage2;
        priority_encoded  <= (8'h01 << highest_idx_stage2);
        reset_out         <= 1'b1;
      end else begin
        active_priority   <= 3'h7;
        priority_encoded  <= 8'h00;
        reset_out         <= 1'b0;
      end
    end
  end

  // Output AXI-Stream signals
  assign m_axis_tvalid = s_axis_tvalid_stage2;
  assign m_axis_tdata  = {active_priority, priority_encoded, reset_out, 3'b000}; // 3+8+1+3=15bits, but only 14 bits used
  assign m_axis_tlast  = 1'b1; // always single beat per transfer

endmodule