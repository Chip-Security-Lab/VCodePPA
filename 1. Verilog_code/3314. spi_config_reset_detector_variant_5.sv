//SystemVerilog
module spi_config_reset_detector_axi_stream (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        spi_cs,
  input  wire        spi_sck,
  input  wire        spi_mosi,
  input  wire [3:0]  reset_sources,
  // AXI-Stream output interface
  output wire [7:0]  m_axis_tdata,
  output wire        m_axis_tvalid,
  input  wire        m_axis_tready,
  output wire        m_axis_tlast
);

  // SPI pipeline registers
  reg [7:0] spi_shift_reg_stage1, spi_shift_reg_stage2;
  reg [7:0] config_reg_stage1, config_reg_stage2;

  // SPI shift logic pipeline
  always @(posedge spi_sck or negedge rst_n) begin
    if (!rst_n) begin
      spi_shift_reg_stage1 <= 8'h00;
    end else if (!spi_cs) begin
      spi_shift_reg_stage1 <= {spi_shift_reg_stage1[6:0], spi_mosi};
    end
  end

  // Pipeline stage for spi_shift_reg
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      spi_shift_reg_stage2 <= 8'h00;
    end else begin
      spi_shift_reg_stage2 <= spi_shift_reg_stage1;
    end
  end

  // Config register update pipeline
  reg config_reg_update_stage1, config_reg_update_stage2;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      config_reg_update_stage1 <= 1'b0;
    end else begin
      config_reg_update_stage1 <= (!spi_cs);
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      config_reg_update_stage2 <= 1'b0;
    end else begin
      config_reg_update_stage2 <= config_reg_update_stage1;
    end
  end

  // Config register pipeline
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      config_reg_stage1 <= 8'h0F;
    end else if (config_reg_update_stage1) begin
      config_reg_stage1 <= spi_shift_reg_stage2;
    end else begin
      config_reg_stage1 <= config_reg_stage1;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      config_reg_stage2 <= 8'h0F;
    end else if (config_reg_update_stage2) begin
      config_reg_stage2 <= config_reg_stage1;
    end else begin
      config_reg_stage2 <= config_reg_stage2;
    end
  end

  // Reset detection pipeline
  reg [3:0] reset_mask_stage1, reset_mask_stage2;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reset_mask_stage1 <= 4'b0000;
    end else begin
      reset_mask_stage1 <= reset_sources & config_reg_stage2[3:0];
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reset_mask_stage2 <= 4'b0000;
    end else begin
      reset_mask_stage2 <= reset_mask_stage1;
    end
  end

  // AXI-Stream output logic
  reg        axi_stream_valid_reg;
  reg [7:0]  axi_stream_data_reg;
  reg        axi_stream_last_reg;
  wire [7:0] reset_and_master_data;
  wire       reset_and_master_nonzero;

  assign reset_and_master_data = {4'b0, reset_mask_stage2};
  assign reset_and_master_nonzero = |reset_mask_stage2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      axi_stream_valid_reg <= 1'b0;
      axi_stream_data_reg  <= 8'h00;
      axi_stream_last_reg  <= 1'b0;
    end else begin
      if (reset_and_master_nonzero) begin
        if (!axi_stream_valid_reg || (axi_stream_valid_reg && m_axis_tready)) begin
          axi_stream_valid_reg <= 1'b1;
          axi_stream_data_reg  <= {4'b0, reset_mask_stage2};
          axi_stream_last_reg  <= 1'b1;
        end else if (axi_stream_valid_reg && m_axis_tready) begin
          axi_stream_valid_reg <= 1'b0;
          axi_stream_data_reg  <= 8'h00;
          axi_stream_last_reg  <= 1'b0;
        end
      end else begin
        if (axi_stream_valid_reg && m_axis_tready) begin
          axi_stream_valid_reg <= 1'b0;
          axi_stream_data_reg  <= 8'h00;
          axi_stream_last_reg  <= 1'b0;
        end
      end
    end
  end

  assign m_axis_tdata  = axi_stream_data_reg;
  assign m_axis_tvalid = axi_stream_valid_reg;
  assign m_axis_tlast  = axi_stream_last_reg;

endmodule