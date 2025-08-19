//SystemVerilog
module reset_sync_ring (
  // Clock and reset
  input  wire        clk,
  input  wire        rst_n,
  
  // Input interface with Valid-Ready handshake
  input  wire        in_valid,
  output wire        in_ready,
  input  wire [3:0]  in_data,
  input  wire        in_last,
  
  // Output interface with Valid-Ready handshake
  output wire        out_valid,
  input  wire        out_ready,
  output wire [3:0]  out_data,
  output wire        out_last
);

  // Internal signals
  reg [3:0] ring_reg;
  reg       valid_reg;
  reg       last_reg;
  reg       processing;
  
  // Handshake logic - can accept new data when not processing or when output is being transferred
  assign in_ready = rst_n && (!valid_reg || (valid_reg && out_ready));
  
  // Valid output when we have processed data and haven't transferred it yet
  assign out_valid = valid_reg;
  assign out_data = ring_reg;
  assign out_last = last_reg;
  
  // Data capture and processing logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ring_reg <= 4'b1000;
      valid_reg <= 1'b0;
      last_reg <= 1'b0;
      processing <= 1'b0;
    end else begin
      // Handle input data when valid handshake occurs
      if (in_valid && in_ready) begin
        ring_reg <= in_data;
        last_reg <= in_last;
        valid_reg <= 1'b1;
        processing <= 1'b1;
      end 
      // Handle output transfer
      else if (out_valid && out_ready) begin
        valid_reg <= 1'b0;
        processing <= 1'b0;
      end
      // Perform ring rotation when processing but no valid I/O transfers
      else if (processing && !valid_reg) begin
        ring_reg <= {ring_reg[2:0], ring_reg[3]};
        valid_reg <= 1'b1;
      end
      else if (processing) begin
        // Continue rotation during processing when output not being read
        ring_reg <= {ring_reg[2:0], ring_reg[3]};
      end
    end
  end
  
  // Debug signal (maintained from original design)
  wire out_rst = ring_reg[0];
  
endmodule