//SystemVerilog
module spi_config_reset_detector(
  input  wire        clk,
  input  wire        rst_n,
  input  wire        spi_cs,
  input  wire        spi_sck,
  input  wire        spi_mosi,
  input  wire [3:0]  reset_sources,
  output reg  [3:0]  reset_detected,
  output reg         master_reset
);

  // SPI configuration register
  reg [7:0] config_reg = 8'h0F;
  reg [7:0] spi_shift_reg = 8'h00;

  // SPI shift logic (synchronous, glitch-free)
  always @(posedge spi_sck or negedge rst_n) begin
    if (!rst_n) begin
      spi_shift_reg <= 8'h00;
    end else if (!spi_cs) begin
      spi_shift_reg <= {spi_shift_reg[6:0], spi_mosi};
    end
  end

  // Latch configuration on SPI chip select deassertion
  always @(negedge spi_cs or negedge rst_n) begin
    if (!rst_n) begin
      config_reg <= 8'h0F;
    end else begin
      config_reg <= spi_shift_reg;
    end
  end

  // Optimized reset detection logic
  wire [3:0] enabled_resets;
  assign enabled_resets = reset_sources & config_reg[3:0];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reset_detected <= 4'b0000;
      master_reset   <= 1'b0;
    end else begin
      reset_detected <= enabled_resets;
      master_reset   <= (enabled_resets != 4'b0000);
    end
  end

endmodule