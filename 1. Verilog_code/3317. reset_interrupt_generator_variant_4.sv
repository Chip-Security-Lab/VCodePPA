//SystemVerilog
module reset_interrupt_generator_valid_ready (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [5:0]  reset_sources,       // Active high
  input  wire [5:0]  interrupt_mask,      // 1=generate interrupt
  input  wire        interrupt_ack_valid, // Valid signal for ack input
  input  wire        interrupt_ack,       // Ack data input
  output reg         interrupt_valid,     // Valid signal for interrupt output
  input  wire        interrupt_ready,     // Ready signal for interrupt output
  output reg  [5:0]  pending_sources,
  output reg  [5:0]  interrupt_sources    // Output the sources that triggered the interrupt
);

  reg  [5:0] prev_sources;
  reg  [5:0] pending_sources_next;
  reg        interrupt_pending;
  reg  [5:0] interrupt_sources_reg;

  wire [5:0] new_resets = (reset_sources & ~prev_sources) & interrupt_mask;
  wire       new_interrupt_event = |(pending_sources | new_resets);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_sources         <= 6'h00;
      pending_sources      <= 6'h00;
      interrupt_valid      <= 1'b0;
      interrupt_pending    <= 1'b0;
      interrupt_sources_reg<= 6'h00;
    end else begin
      prev_sources <= reset_sources;

      // Handle pending_sources with valid-ready handshake for interrupt_ack
      if (interrupt_ack_valid && interrupt_ack) begin
        pending_sources <= 6'h00;
      end else begin
        pending_sources <= pending_sources | new_resets;
      end

      // Latch interrupt and sources when event occurs and handshake is successful
      if (new_interrupt_event && !interrupt_pending) begin
        interrupt_pending     <= 1'b1;
        interrupt_sources_reg <= pending_sources | new_resets;
      end else if (interrupt_valid && interrupt_ready) begin
        interrupt_pending     <= 1'b0;
        interrupt_sources_reg <= 6'h00;
      end

      // Output valid when interrupt is pending
      interrupt_valid <= interrupt_pending;

    end
  end

  assign interrupt_sources = interrupt_sources_reg;

endmodule