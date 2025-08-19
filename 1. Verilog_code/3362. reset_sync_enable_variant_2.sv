//SystemVerilog - IEEE 1364-2005 Standard
module reset_sync_enable(
  input  wire clk,
  input  wire en,
  input  wire rst_n,
  output reg  sync_reset
);
  reg flop1;
  reg flop1_buf1, flop1_buf2;  // Buffer registers for flop1
  
  // Move the enable logic before the registers
  // to reduce input-to-register delay
  wire en_gated = en & rst_n;
  
  // First stage: flop1 logic with enable gating
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      flop1 <= 1'b0;
    end else begin
      // Enable logic moved before registers
      // This removes enable from the critical timing path
      flop1 <= en_gated | (flop1 & ~en_gated);
    end
  end
  
  // Second stage: buffering for flop1 signal to manage fanout
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      flop1_buf1 <= 1'b0;
      flop1_buf2 <= 1'b0;
    end else begin
      // Fan-out buffering for flop1 signal
      flop1_buf1 <= flop1;
      flop1_buf2 <= flop1;
    end
  end
  
  // Final stage: generate synchronized reset output
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      sync_reset <= 1'b0;
    end else begin
      // Use buffered version of flop1 to drive sync_reset
      sync_reset <= flop1_buf1;
    end
  end
endmodule