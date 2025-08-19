module reset_interrupt_generator(
  input clk, rst_n,
  input [5:0] reset_sources, // Active high
  input [5:0] interrupt_mask, // 1=generate interrupt
  input interrupt_ack,
  output reg interrupt,
  output reg [5:0] pending_sources
);
  reg [5:0] prev_sources = 6'h00;
  wire [5:0] new_resets = (reset_sources & ~prev_sources) & interrupt_mask;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_sources <= 6'h00;
      pending_sources <= 6'h00;
      interrupt <= 1'b0;
    end else begin
      prev_sources <= reset_sources;
      pending_sources <= interrupt_ack ? 6'h00 : (pending_sources | new_resets);
      interrupt <= |(pending_sources | new_resets);
    end
  end
endmodule