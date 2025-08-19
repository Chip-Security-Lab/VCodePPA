//SystemVerilog
// SystemVerilog
module mipi_soundwire_controller (
  input wire clk,
  input wire reset_n,
  input wire [15:0] audio_in,
  input wire audio_valid,
  output reg sdout,
  output reg sclk,
  output reg ws,
  output reg ready
);

  // Internal registers for core state
  reg [7:0] bit_count_reg;
  reg [15:0] shift_reg;
  reg ws_reg;
  reg ready_reg;

  // Internal registers for sclk generation and edge detection
  reg sclk_gen_reg;      // Toggles on clk posedge to create clk/2
  reg sclk_gen_prev_reg; // Previous value of sclk_gen_reg

  // Derived signals for sclk edge detection (within clk domain)
  wire sclk_rising_edge;
  wire sclk_falling_edge;

  assign sclk_rising_edge = sclk_gen_reg && !sclk_gen_prev_reg;
  assign sclk_falling_edge = !sclk_gen_reg && sclk_gen_prev_reg;

  //--------------------------------------------------------------------------
  // Stage 1: sclk generation and edge detection
  // Synchronized to the main clk
  //--------------------------------------------------------------------------
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      sclk_gen_reg <= 1'b0;
      sclk_gen_prev_reg <= 1'b0;
    end else begin
      sclk_gen_prev_reg <= sclk_gen_reg;
      sclk_gen_reg <= ~sclk_gen_reg; // Standard clk/2 toggle
    end
  end

  //--------------------------------------------------------------------------
  // Stage 2: Core State and Data Path Logic
  // Updates based on detected sclk edges, synchronized to clk
  //--------------------------------------------------------------------------
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      bit_count_reg <= 8'd0;
      shift_reg <= 16'd0;
      ws_reg <= 1'b0;
      ready_reg <= 1'b1;
    end else begin
      // Logic based on sclk edges (derived in Stage 1)
      if (sclk_rising_edge) begin
        // Actions corresponding to original sclk rising edge
        if (bit_count_reg == 8'd0 && audio_valid && ready_reg) begin
          shift_reg <= audio_in;
          ready_reg <= 1'b0; // Ready goes low when loading starts
        end

        if (bit_count_reg == 8'd15) begin
          ws_reg <= ~ws_reg;
          ready_reg <= 1'b1; // Ready goes high at the end of a frame
        end
      end else if (sclk_falling_edge) begin
        // Actions corresponding to original sclk falling edge
        // Shift shift_reg
        shift_reg <= {shift_reg[14:0], 1'b0}; // Shift left

        // Update bit_count
        bit_count_reg <= (bit_count_reg == 8'd15) ? 8'd0 : bit_count_reg + 1'b1;
      end
    end
  end

  //--------------------------------------------------------------------------
  // Stage 3: Output Registration
  // Registering outputs for improved timing and clear interface
  // Synchronized to the main clk
  //--------------------------------------------------------------------------
  always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
          sdout <= 1'b0;
          sclk <= 1'b0;
          ws <= 1'b0;
          ready <= 1'b1;
      end else begin
          // sclk output is the derived clock signal (registered version)
          sclk <= sclk_gen_reg;
          // ws and ready outputs are registered state signals
          ws <= ws_reg;
          ready <= ready_reg;

          // sdout is based on shift_reg[15] on sclk falling edge.
          // Capture the value on the clk edge when sclk_falling_edge is true.
          if (sclk_falling_edge) begin
              sdout <= shift_reg[15];
          end
      end
  end

  // frame_count from original code was unused and is removed.

endmodule