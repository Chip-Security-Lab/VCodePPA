//SystemVerilog
module moore_2state_parity_gen_axi_stream (
  input  wire        aclk,
  input  wire        aresetn,
  input  wire        s_axis_tvalid,
  output wire        s_axis_tready,
  input  wire [7:0]  s_axis_tdata,
  input  wire        s_axis_tlast,
  output wire        m_axis_tvalid,
  input  wire        m_axis_tready,
  output wire [7:0]  m_axis_tdata,
  output wire        m_axis_tlast
);

  // State definitions
  localparam STATE_EVEN = 1'b0,
             STATE_ODD  = 1'b1;
  
  // Internal signals
  reg current_state;
  reg next_state;
  reg parity_reg;
  reg [7:0] data_reg;
  reg valid_reg;
  reg last_reg;
  
  // AXI-Stream handshake signals
  assign s_axis_tready = ~valid_reg || (valid_reg && m_axis_tready);
  assign m_axis_tvalid = valid_reg;
  assign m_axis_tdata = {7'b0, parity_reg};
  assign m_axis_tlast = last_reg;
  
  // State transition logic - converted from case to if-else
  always @* begin
    if (current_state == STATE_EVEN) begin
      if (s_axis_tdata[0])
        next_state = STATE_ODD;
      else
        next_state = STATE_EVEN;
    end
    else if (current_state == STATE_ODD) begin
      if (s_axis_tdata[0])
        next_state = STATE_EVEN;
      else
        next_state = STATE_ODD;
    end
    else begin
      next_state = STATE_EVEN;
    end
  end
  
  // Sequential logic
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      current_state <= STATE_EVEN;
      parity_reg <= 1'b0;
      valid_reg <= 1'b0;
      last_reg <= 1'b0;
      data_reg <= 8'b0;
    end else begin
      if (s_axis_tvalid && s_axis_tready) begin
        current_state <= next_state;
        parity_reg <= (next_state == STATE_ODD);
        valid_reg <= 1'b1;
        last_reg <= s_axis_tlast;
        data_reg <= s_axis_tdata;
      end else if (m_axis_tready) begin
        valid_reg <= 1'b0;
      end
    end
  end

endmodule