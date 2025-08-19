module spi_config_reset_detector(
  input clk, rst_n, spi_cs, spi_sck, spi_mosi,
  input [3:0] reset_sources,
  output reg [3:0] reset_detected,
  output reg master_reset
);
  // SPI registers
  reg [7:0] config_reg = 8'h0F; // Default: all sources enabled
  reg [1:0] spi_bit_count = 2'b00;
  reg [7:0] spi_shift_reg = 8'h00;
  
  // SPI interface logic
  always @(posedge spi_sck or negedge rst_n) begin
    if (!rst_n)
      spi_shift_reg <= 8'h00;
    else if (!spi_cs)
      spi_shift_reg <= {spi_shift_reg[6:0], spi_mosi};
  end
  
  always @(negedge spi_cs or negedge rst_n) begin
    if (!rst_n)
      config_reg <= 8'h0F;
    else
      config_reg <= spi_shift_reg;
  end
  
  // Reset detection logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reset_detected <= 4'b0000;
      master_reset <= 1'b0;
    end else begin
      reset_detected <= reset_sources & config_reg[3:0];
      master_reset <= |(reset_sources & config_reg[3:0]);
    end
  end
endmodule