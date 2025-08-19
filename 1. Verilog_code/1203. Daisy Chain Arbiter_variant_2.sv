//SystemVerilog
module daisy_chain_arbiter_axi(
  input  wire         clk,
  input  wire         reset,
  
  // AXI-Stream Slave Interface
  input  wire [3:0]   s_axis_tdata,
  input  wire         s_axis_tvalid,
  output wire         s_axis_tready,
  
  // AXI-Stream Master Interface
  output wire [3:0]   m_axis_tdata,
  output wire         m_axis_tvalid,
  input  wire         m_axis_tready
);

  // Internal signals
  reg  [3:0] grant;
  wire [3:0] request;
  reg        grant_valid;
  wire [1:0] priority_index;
  
  // Map input AXI-Stream to request
  assign request = s_axis_tvalid ? s_axis_tdata : 4'b0000;
  
  // AXI-Stream handshaking
  assign s_axis_tready = !reset;  // Ready to receive when not in reset
  assign m_axis_tvalid = grant_valid;
  assign m_axis_tdata = grant;
  
  // Determine priority based on request bits
  assign priority_index = request[0] ? 2'd0 :
                          request[1] ? 2'd1 :
                          request[2] ? 2'd2 :
                          request[3] ? 2'd3 : 2'd0;
  
  // Register update with balanced paths
  always @(posedge clk) begin
    if (reset) begin
      grant <= 4'h0;
      grant_valid <= 1'b0;
    end
    else begin
      // Only update grant when input is valid and output is ready (or not valid)
      if (s_axis_tvalid && (m_axis_tready || !grant_valid)) begin
        // Use case statement instead of parallel calculation
        case (priority_index)
          2'd0: grant <= 4'b0001; // Grant request 0 (highest priority)
          2'd1: grant <= 4'b0010; // Grant request 1
          2'd2: grant <= 4'b0100; // Grant request 2
          2'd3: grant <= 4'b1000; // Grant request 3 (lowest priority)
          default: grant <= 4'b0000;
        endcase
        grant_valid <= |request; // Valid if any request is active
      end
      else if (m_axis_tready) begin
        // Clear valid flag once data is consumed
        grant_valid <= 1'b0;
      end
    end
  end
endmodule