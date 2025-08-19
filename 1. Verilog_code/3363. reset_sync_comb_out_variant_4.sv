//SystemVerilog
module reset_sync_comb_out (
  // Clock and reset
  input  wire        clk,
  input  wire        rst_in,
  
  // AXI-Stream master interface
  output wire        m_axis_tvalid,
  input  wire        m_axis_tready,
  output wire [0:0]  m_axis_tdata,
  output wire        m_axis_tlast
);

  // Internal registers for reset synchronization
  reg flop_a, flop_b, rst_out_reg;
  
  // Reset synchronization logic
  always @(posedge clk or negedge rst_in) begin
    if (!rst_in) begin
      flop_a <= 1'b0;
      flop_b <= 1'b0;
      rst_out_reg <= 1'b0;
    end else begin
      flop_a <= 1'b1;
      flop_b <= flop_a;
      rst_out_reg <= flop_b & flop_a;
    end
  end
  
  // AXI-Stream interface assignments
  // Always valid when reset is processed
  assign m_axis_tvalid = 1'b1;
  
  // The reset output is mapped to tdata
  assign m_axis_tdata = rst_out_reg;
  
  // Assert tlast signal (can be used to indicate complete reset sequence)
  assign m_axis_tlast = rst_out_reg;
  
endmodule