//SystemVerilog
module prio_enc_sync_rst #(parameter WIDTH=8, ADDR=3)(
  input clk,
  input rst_n,
  input [WIDTH-1:0] req_in,
  output reg [ADDR-1:0] addr_out
);

  // Internal signals
  reg [ADDR-1:0] next_addr;
  reg found;

  // Priority encoder logic
  always @(*) begin
    next_addr = {ADDR{1'b0}};
    found = 1'b0;
    
    if (req_in[7] && !found) begin
      next_addr = 3'd7;
      found = 1'b1;
    end else if (req_in[6] && !found) begin
      next_addr = 3'd6;
      found = 1'b1;
    end else if (req_in[5] && !found) begin
      next_addr = 3'd5;
      found = 1'b1;
    end else if (req_in[4] && !found) begin
      next_addr = 3'd4;
      found = 1'b1;
    end else if (req_in[3] && !found) begin
      next_addr = 3'd3;
      found = 1'b1;
    end else if (req_in[2] && !found) begin
      next_addr = 3'd2;
      found = 1'b1;
    end else if (req_in[1] && !found) begin
      next_addr = 3'd1;
      found = 1'b1;
    end else if (req_in[0] && !found) begin
      next_addr = 3'd0;
      found = 1'b1;
    end
  end

  // Synchronous reset and output register
  always @(posedge clk) begin
    if (!rst_n) begin
      addr_out <= {ADDR{1'b0}};
    end else begin
      addr_out <= next_addr;
    end
  end

endmodule