//SystemVerilog
module spi_config_reset_detector_axi_stream (
  input  wire        clk,
  input  wire        rst_n,
  // AXI-Stream Slave (SPI data in)
  input  wire [7:0]  s_axis_tdata,
  input  wire        s_axis_tvalid,
  output wire        s_axis_tready,
  // AXI-Stream Master (config out, if needed)
  output wire [3:0]  m_axis_tdata,
  output wire        m_axis_tvalid,
  input  wire        m_axis_tready,
  // Reset sources input
  input  wire [3:0]  reset_sources,
  output reg  [3:0]  reset_detected,
  output reg         master_reset
);

  // Internal registers
  reg [7:0] config_reg;
  reg       config_reg_valid;

  // AXI-Stream handshake logic for slave
  assign s_axis_tready = !config_reg_valid;

  // Capture config_reg when new data arrives
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      config_reg      <= 8'h0F;
      config_reg_valid<= 1'b0;
    end else begin
      if (s_axis_tvalid && s_axis_tready) begin
        config_reg      <= s_axis_tdata;
        config_reg_valid<= 1'b1;
      end else if (config_reg_valid && m_axis_tvalid && m_axis_tready) begin
        config_reg_valid<= 1'b0;
      end
    end
  end

  // Reset detection logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reset_detected <= 4'b0000;
      master_reset   <= 1'b0;
    end else begin
      reset_detected <= reset_sources & config_reg[3:0];
      master_reset   <= |(reset_sources & config_reg[3:0]);
    end
  end

  // AXI-Stream output logic (send detected reset status)
  assign m_axis_tdata  = reset_detected;
  assign m_axis_tvalid = config_reg_valid;

endmodule