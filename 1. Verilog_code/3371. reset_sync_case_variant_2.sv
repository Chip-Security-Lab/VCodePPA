//SystemVerilog
module reset_sync_axi_stream (
  // Clock and reset
  input  wire        clk,
  input  wire        rst_n,
  
  // AXI-Stream interface
  input  wire        s_axis_tvalid,  // Input valid signal
  output wire        s_axis_tready,  // Ready to accept data
  input  wire [0:0]  s_axis_tdata,   // Input data (1-bit)
  
  output reg         m_axis_tvalid,  // Output valid signal
  input  wire        m_axis_tready,  // Downstream ready
  output reg  [0:0]  m_axis_tdata,   // Output data (1-bit)
  output reg         m_axis_tlast    // Last signal (optional)
);

  // Internal registers for synchronization
  reg stage1;
  reg rst_sync;
  
  // Register input valid to balance timing paths
  reg s_axis_tvalid_reg;
  
  // Synchronization process
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1 <= 1'b0;
      rst_sync <= 1'b0;
      s_axis_tvalid_reg <= 1'b0;
    end else begin
      stage1 <= 1'b1;
      rst_sync <= stage1;
      s_axis_tvalid_reg <= s_axis_tvalid;
    end
  end
  
  // AXI-Stream output registers
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m_axis_tvalid <= 1'b0;
      m_axis_tdata <= 1'b0;
      m_axis_tlast <= 1'b0;
    end else begin
      m_axis_tvalid <= s_axis_tvalid_reg;
      m_axis_tdata <= rst_sync;
      m_axis_tlast <= 1'b0;  // Not using packet boundaries
    end
  end
  
  // Always ready to accept new data
  assign s_axis_tready = m_axis_tready;

endmodule