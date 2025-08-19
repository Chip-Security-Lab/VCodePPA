//SystemVerilog
module reset_freq_counter(
  input  wire        clk,
  input  wire        rst_n,
  input  wire        ext_rst_n,
  input  wire        wdt_rst_n,
  output reg  [7:0]  ext_rst_count,
  output reg  [7:0]  wdt_rst_count,
  output reg         any_reset
);

  // Pipeline stage 1: Sample inputs and previous values
  reg ext_rst_n_q1, wdt_rst_n_q1;
  reg ext_rst_prev_q1, wdt_rst_prev_q1;

  // Pipeline stage 2: Generate falling edge and any_reset signals
  reg ext_rst_falling_q2, wdt_rst_falling_q2;
  reg any_reset_next_q2;

  // Pipeline stage 3: Registered output update
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ext_rst_n_q1      <= 1'b1;
      wdt_rst_n_q1      <= 1'b1;
      ext_rst_prev_q1   <= 1'b1;
      wdt_rst_prev_q1   <= 1'b1;

      ext_rst_falling_q2 <= 1'b0;
      wdt_rst_falling_q2 <= 1'b0;
      any_reset_next_q2  <= 1'b0;

      ext_rst_count      <= 8'h00;
      wdt_rst_count      <= 8'h00;
      any_reset          <= 1'b0;
    end else begin
      // Stage 1: Register inputs and previous values
      ext_rst_n_q1      <= ext_rst_n;
      wdt_rst_n_q1      <= wdt_rst_n;
      ext_rst_prev_q1   <= ext_rst_n_q1;
      wdt_rst_prev_q1   <= wdt_rst_n_q1;

      // Stage 2: Detect falling edge and any_reset signal
      ext_rst_falling_q2 <= ext_rst_prev_q1 & ~ext_rst_n_q1;
      wdt_rst_falling_q2 <= wdt_rst_prev_q1 & ~wdt_rst_n_q1;
      any_reset_next_q2  <= (~ext_rst_n_q1) | (~wdt_rst_n_q1);

      // Stage 3: Update output registers
      ext_rst_count      <= ext_rst_falling_q2 ? (ext_rst_count + 1'b1) : ext_rst_count;
      wdt_rst_count      <= wdt_rst_falling_q2 ? (wdt_rst_count + 1'b1) : wdt_rst_count;
      any_reset          <= any_reset_next_q2;
    end
  end

endmodule