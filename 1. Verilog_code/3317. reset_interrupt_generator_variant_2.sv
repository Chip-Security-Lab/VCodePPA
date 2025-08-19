//SystemVerilog
module reset_interrupt_generator(
  input clk, rst_n,
  input [5:0] reset_sources, // Active high
  input [5:0] interrupt_mask, // 1=generate interrupt
  input interrupt_ack,
  output reg interrupt,
  output reg [5:0] pending_sources
);
  reg [5:0] prev_sources = 6'h00;
  wire [5:0] new_resets;
  reg [5:0] next_pending_sources;
  reg next_interrupt;

  assign new_resets = (reset_sources & ~prev_sources) & interrupt_mask;

  always @(*) begin
    if (interrupt_ack) begin
      next_pending_sources = 6'h00;
    end else begin
      next_pending_sources = pending_sources | new_resets;
    end

    if ((|next_pending_sources) == 1'b1) begin
      next_interrupt = 1'b1;
    end else begin
      next_interrupt = 1'b0;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_sources <= 6'h00;
      pending_sources <= 6'h00;
      interrupt <= 1'b0;
    end else begin
      prev_sources <= reset_sources;
      pending_sources <= next_pending_sources;
      interrupt <= next_interrupt;
    end
  end
endmodule