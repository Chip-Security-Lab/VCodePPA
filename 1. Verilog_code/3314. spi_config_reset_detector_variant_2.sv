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

  // SPI registers
  reg [7:0] spi_config_reg = 8'h0F;
  reg [7:0] spi_shift_reg  = 8'h00;

  // SPI interface logic
  always @(posedge spi_sck or negedge rst_n) begin
    if (!rst_n) begin
      spi_shift_reg <= 8'h00;
    end else if (!spi_cs) begin
      spi_shift_reg <= {spi_shift_reg[6:0], spi_mosi};
    end
  end

  always @(negedge spi_cs or negedge rst_n) begin
    if (!rst_n) begin
      spi_config_reg <= 8'h0F;
    end else begin
      spi_config_reg <= spi_shift_reg;
    end
  end

  // Optimized reset detection logic
  wire [3:0] mask_resets;
  assign mask_resets = reset_sources & spi_config_reg[3:0];

  wire mask_resets_nonzero;
  assign mask_resets_nonzero = |mask_resets;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reset_detected <= 4'b0000;
      master_reset   <= 1'b0;
    end else begin
      reset_detected <= mask_resets;
      master_reset   <= mask_resets_nonzero;
    end
  end

endmodule