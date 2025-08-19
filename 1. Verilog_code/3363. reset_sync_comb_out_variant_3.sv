//SystemVerilog
module reset_sync_comb_out(
  input  wire clk,
  input  wire rst_in,
  output wire rst_out
);
  // Reset synchronization registers
  (* dont_touch = "true" *) reg [1:0] sync_flop_a;
  (* dont_touch = "true" *) reg [1:0] sync_flop_b;
  (* dont_touch = "true" *) reg [1:0] sync_valid;

  // Combined synchronization process
  always @(posedge clk or negedge rst_in) begin
    if(!rst_in) begin
      sync_flop_a <= 2'b00;
      sync_flop_b <= 2'b00;
      sync_valid <= 2'b00;
    end else begin
      // Shift register implementation for better timing
      sync_flop_a <= {sync_flop_a[0], 1'b1};
      sync_flop_b <= {sync_flop_b[0], sync_flop_a[0]};
      sync_valid <= {sync_valid[0], 1'b1};
    end
  end
  
  // Optimized output logic with priority encoding
  assign rst_out = (sync_valid[1] && (sync_flop_a[1] && sync_flop_b[1]));
endmodule