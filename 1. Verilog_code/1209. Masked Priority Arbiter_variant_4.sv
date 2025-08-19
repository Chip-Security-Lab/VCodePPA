//SystemVerilog
module masked_priority_arbiter(
  input  wire        clk,
  input  wire        rst_n,
  
  // AXI-Stream input interface
  input  wire [3:0]  s_axis_tdata,    // Request data
  input  wire [3:0]  s_axis_tuser,    // Mask data
  input  wire        s_axis_tvalid,   // Input valid signal
  output wire        s_axis_tready,   // Ready to accept data
  
  // AXI-Stream output interface
  output wire [3:0]  m_axis_tdata,    // Grant data
  output reg         m_axis_tvalid,   // Output valid signal
  input  wire        m_axis_tready    // Downstream ready signal
);

  // Internal signals
  reg  [3:0] grant;
  wire [3:0] req, mask;
  wire [3:0] masked_req;
  reg  [2:0] priority_idx;
  reg        processing;
  
  // Input interface handling
  assign s_axis_tready = !processing || (m_axis_tvalid && m_axis_tready);
  assign req = s_axis_tvalid ? s_axis_tdata : 4'b0;
  assign mask = s_axis_tvalid ? s_axis_tuser : 4'b0;
  assign masked_req = req & ~mask;
  
  // Output interface handling
  assign m_axis_tdata = grant;
  
  // Priority logic
  always @(*) begin
    priority_idx = 3'd7; // Default: no valid request
    
    casez (masked_req)
      4'b???1: priority_idx = 3'd0;
      4'b??10: priority_idx = 3'd1;
      4'b?100: priority_idx = 3'd2;
      4'b1000: priority_idx = 3'd3;
      default: priority_idx = 3'd7;
    endcase
  end
  
  // State management and grant calculation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant <= 4'h0;
      m_axis_tvalid <= 1'b0;
      processing <= 1'b0;
    end else begin
      if (s_axis_tvalid && s_axis_tready) begin
        // New request received
        processing <= 1'b1;
        grant <= 4'h0;
        
        case (priority_idx)
          3'd0: grant[0] <= 1'b1;
          3'd1: grant[1] <= 1'b1;
          3'd2: grant[2] <= 1'b1;
          3'd3: grant[3] <= 1'b1;
          default: grant <= 4'h0;
        endcase
        
        m_axis_tvalid <= 1'b1;
      end else if (m_axis_tvalid && m_axis_tready) begin
        // Handshake complete
        m_axis_tvalid <= 1'b0;
        processing <= 1'b0;
      end
    end
  end
  
endmodule