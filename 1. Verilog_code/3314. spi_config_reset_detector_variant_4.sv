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
  reg [7:0] config_reg_q, config_reg_d;
  reg [7:0] spi_shift_reg_q, spi_shift_reg_d;

  // SPI shift enable
  wire spi_shift_active = ~spi_cs;

  // Optimized SPI shift logic
  always @(*) begin
    if (!rst_n) begin
      spi_shift_reg_d = 8'h00;
    end else if (spi_shift_active) begin
      spi_shift_reg_d = {spi_shift_reg_q[6:0], spi_mosi};
    end else begin
      spi_shift_reg_d = spi_shift_reg_q;
    end
  end

  always @(posedge spi_sck or negedge rst_n) begin
    if (!rst_n)
      spi_shift_reg_q <= 8'h00;
    else
      spi_shift_reg_q <= spi_shift_reg_d;
  end

  // Optimized Config register update
  always @(*) begin
    if (!rst_n) begin
      config_reg_d = 8'h0F;
    end else if (spi_shift_active) begin
      config_reg_d = spi_shift_reg_q;
    end else begin
      config_reg_d = config_reg_q;
    end
  end

  always @(negedge spi_cs or negedge rst_n) begin
    if (!rst_n)
      config_reg_q <= 8'h0F;
    else
      config_reg_q <= config_reg_d;
  end

  // Optimized reset detection logic
  wire [3:0] detected_resets;
  assign detected_resets = reset_sources & config_reg_q[3:0];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reset_detected <= 4'b0000;
      master_reset   <= 1'b0;
    end else begin
      reset_detected <= detected_resets;
      master_reset   <= (detected_resets != 4'b0000);
    end
  end

endmodule