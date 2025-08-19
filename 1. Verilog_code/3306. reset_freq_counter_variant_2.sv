//SystemVerilog
module reset_freq_counter_valid_ready (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        ext_rst_n,
  input  wire        wdt_rst_n,
  input  wire        out_ready,
  output reg  [7:0]  ext_rst_count,
  output reg  [7:0]  wdt_rst_count,
  output reg         any_reset,
  output reg         out_valid
);

  reg ext_rst_prev, wdt_rst_prev;
  reg [7:0] ext_rst_count_inc, wdt_rst_count_inc;
  reg ext_rst_fall, wdt_rst_fall;
  reg reset_event;
  reg any_reset_comb;
  reg out_valid_comb;

  // Pre-calculate edge detection and combinational outputs
  always @(*) begin
    ext_rst_fall     = ext_rst_prev & ~ext_rst_n;
    wdt_rst_fall     = wdt_rst_prev & ~wdt_rst_n;
    reset_event      = ext_rst_fall | wdt_rst_fall;

    ext_rst_count_inc = ext_rst_count + {{7{1'b0}}, ext_rst_fall};
    wdt_rst_count_inc = wdt_rst_count + {{7{1'b0}}, wdt_rst_fall};

    any_reset_comb   = ~ext_rst_n | ~wdt_rst_n;
    out_valid_comb   = reset_event;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ext_rst_prev    <= 1'b1;
      wdt_rst_prev    <= 1'b1;
      ext_rst_count   <= 8'h00;
      wdt_rst_count   <= 8'h00;
      any_reset       <= 1'b0;
      out_valid       <= 1'b0;
    end else begin
      ext_rst_prev  <= ext_rst_n;
      wdt_rst_prev  <= wdt_rst_n;

      // Output valid and update logic
      if (out_valid & out_ready) begin
        out_valid   <= 1'b0;
      end else if (out_valid_comb & out_ready) begin
        ext_rst_count <= ext_rst_count_inc;
        wdt_rst_count <= wdt_rst_count_inc;
        any_reset     <= any_reset_comb;
        out_valid     <= 1'b1;
      end else if (!out_valid) begin
        any_reset     <= any_reset_comb;
        out_valid     <= out_valid_comb;
      end
    end
  end

endmodule