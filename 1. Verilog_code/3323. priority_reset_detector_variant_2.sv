//SystemVerilog
// Top-level module: priority_reset_detector_axi_stream
module priority_reset_detector_axi_stream (
  input  wire               clk,
  input  wire               rst_n,

  // AXI-Stream slave interface (input)
  input  wire               s_axis_tvalid,
  output wire               s_axis_tready,
  input  wire [7:0]         s_axis_tdata,        // reset_sources
  input  wire [7:0][2:0]    s_axis_tuser,        // priorities

  // AXI-Stream master interface (output)
  output wire               m_axis_tvalid,
  input  wire               m_axis_tready,
  output wire [13:0]        m_axis_tdata,        // {active_priority[2:0], priority_encoded[7:0], reset_out[0]}
  output wire               m_axis_tlast
);

  // Internal signals
  wire [2:0]  active_priority;
  wire [7:0]  priority_encoded;
  wire        reset_out;
  wire        handshake_start;
  wire        handshake_done;
  wire        data_valid_next;
  wire        data_last_next;

  // Handshake control submodule
  axi_stream_handshake_ctrl u_handshake_ctrl (
    .clk              (clk),
    .rst_n            (rst_n),
    .s_axis_tvalid    (s_axis_tvalid),
    .m_axis_tvalid    (m_axis_tvalid),
    .m_axis_tready    (m_axis_tready),
    .s_axis_tready    (s_axis_tready),
    .handshake_start  (handshake_start),
    .handshake_done   (handshake_done),
    .data_valid_next  (data_valid_next),
    .data_last_next   (data_last_next)
  );

  // Priority and reset logic submodule
  priority_reset_logic u_priority_reset_logic (
    .clk                (clk),
    .rst_n              (rst_n),
    .handshake_start    (handshake_start),
    .handshake_done     (handshake_done),
    .data_valid_next    (data_valid_next),
    .data_last_next     (data_last_next),
    .s_axis_tdata       (s_axis_tdata),
    .s_axis_tuser       (s_axis_tuser),
    .active_priority    (active_priority),
    .priority_encoded   (priority_encoded),
    .reset_out          (reset_out),
    .m_axis_tvalid      (m_axis_tvalid),
    .m_axis_tlast       (m_axis_tlast)
  );

  // Output data packing submodule
  output_data_pack u_output_data_pack (
    .active_priority    (active_priority),
    .priority_encoded   (priority_encoded),
    .reset_out          (reset_out),
    .m_axis_tdata       (m_axis_tdata)
  );

endmodule

//-----------------------------------------------------------------------------
// Submodule: axi_stream_handshake_ctrl
// Purpose: Handles AXI-Stream handshake protocol for input/output readiness and data transfer
//-----------------------------------------------------------------------------
module axi_stream_handshake_ctrl (
  input  wire clk,
  input  wire rst_n,
  input  wire s_axis_tvalid,
  input  wire m_axis_tvalid,
  input  wire m_axis_tready,
  output wire s_axis_tready,
  output wire handshake_start,
  output wire handshake_done,
  output wire data_valid_next,
  output wire data_last_next
);
  // s_axis_tready is asserted when output is not valid or ready to accept new data
  assign s_axis_tready    = ~m_axis_tvalid | (m_axis_tvalid & m_axis_tready);
  assign handshake_start  = s_axis_tvalid & s_axis_tready;
  assign handshake_done   = m_axis_tvalid & m_axis_tready;
  assign data_valid_next  = handshake_start;
  assign data_last_next   = handshake_start;
endmodule

//-----------------------------------------------------------------------------
// Submodule: priority_reset_logic
// Purpose: Implements the priority selection, encoding, and reset output logic
//-----------------------------------------------------------------------------
module priority_reset_logic (
  input  wire           clk,
  input  wire           rst_n,
  input  wire           handshake_start,
  input  wire           handshake_done,
  input  wire           data_valid_next,
  input  wire           data_last_next,
  input  wire [7:0]     s_axis_tdata,
  input  wire [7:0][2:0] s_axis_tuser,
  output reg  [2:0]     active_priority,
  output reg  [7:0]     priority_encoded,
  output reg            reset_out,
  output reg            m_axis_tvalid,
  output reg            m_axis_tlast
);

  integer i;
  integer highest_idx;
  reg [2:0] highest_priority;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      active_priority   <= 3'h7;
      priority_encoded  <= 8'h00;
      reset_out         <= 1'b0;
      m_axis_tvalid     <= 1'b0;
      m_axis_tlast      <= 1'b0;
    end else begin
      if (handshake_start) begin
        highest_priority = 3'h7;
        highest_idx      = 0;
        for (i = 0; i < 8; i = i + 1) begin
          if (s_axis_tdata[i] && (s_axis_tuser[i] < highest_priority)) begin
            highest_priority = s_axis_tuser[i];
            highest_idx      = i;
          end
        end
        active_priority   <= highest_priority;
        priority_encoded  <= (s_axis_tdata != 8'h00) ? (8'h01 << highest_idx) : 8'h00;
        reset_out         <= |s_axis_tdata;
        m_axis_tvalid     <= 1'b1;
        m_axis_tlast      <= 1'b1;
      end else if (handshake_done) begin
        m_axis_tvalid     <= 1'b0;
        m_axis_tlast      <= 1'b0;
      end
    end
  end

endmodule

//-----------------------------------------------------------------------------
// Submodule: output_data_pack
// Purpose: Packs the output data fields into the AXI-Stream data bus
//-----------------------------------------------------------------------------
module output_data_pack (
  input  wire [2:0] active_priority,
  input  wire [7:0] priority_encoded,
  input  wire       reset_out,
  output wire [13:0] m_axis_tdata
);
  assign m_axis_tdata = {active_priority, priority_encoded, reset_out};
endmodule