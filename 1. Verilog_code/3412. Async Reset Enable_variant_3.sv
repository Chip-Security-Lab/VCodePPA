//SystemVerilog
module RD2_AXI (
  // Clock and Reset
  input wire clk,
  input wire rst_n,
  
  // AXI-Stream Slave Interface
  input wire [7:0] s_axis_tdata,
  input wire s_axis_tvalid,
  output wire s_axis_tready,
  
  // AXI-Stream Master Interface
  output wire [7:0] m_axis_tdata,
  output wire m_axis_tvalid,
  input wire m_axis_tready
);

  // Internal registers
  reg [7:0] r_reg;
  reg data_valid;
  
  // Slave interface - ready to accept data when not in reset
  assign s_axis_tready = rst_n;
  
  // Control signals for case statement
  wire slave_handshake;
  wire master_handshake;
  
  assign slave_handshake = s_axis_tvalid && s_axis_tready;
  assign master_handshake = m_axis_tready && data_valid;
  
  // Data registration with reset and valid handshake
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r_reg <= 8'd0;
      data_valid <= 1'b0;
    end else begin
      // Use 2'b concatenation of control signals as case selector
      case ({slave_handshake, master_handshake})
        2'b10: begin // Only slave handshake active
          r_reg <= s_axis_tdata;
          data_valid <= 1'b1;
        end
        2'b01: begin // Only master handshake active
          data_valid <= 1'b0;
        end
        2'b11: begin // Both handshakes active (edge case)
          r_reg <= s_axis_tdata;
          data_valid <= 1'b1;
        end
        default: begin // No handshakes (2'b00)
          r_reg <= r_reg;
          data_valid <= data_valid;
        end
      endcase
    end
  end
  
  // Master interface outputs
  assign m_axis_tdata = r_reg;
  assign m_axis_tvalid = data_valid;

endmodule