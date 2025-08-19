//SystemVerilog
module reset_source_control(
  input  wire        clk,
  input  wire        master_rst_n,
  input  wire [7:0]  reset_sources,
  input  wire [7:0]  enable_mask,
  output reg  [7:0]  reset_status,
  output reg         system_reset
);

  // Stage 1 registers
  reg [7:0] reset_sources_stage1;
  reg [7:0] enable_mask_stage1;

  // Stage 2 registers
  reg [7:0] masked_sources_stage2;

  // Stage 3 registers
  reg [7:0] reset_status_stage3;
  reg       system_reset_stage3;

  // Stage 1: Register reset_sources
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n) begin
      reset_sources_stage1 <= 8'b0;
    end else begin
      reset_sources_stage1 <= reset_sources;
    end
  end

  // Stage 1: Register enable_mask
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n) begin
      enable_mask_stage1 <= 8'b0;
    end else begin
      enable_mask_stage1 <= enable_mask;
    end
  end

  // Stage 2: Compute masked_sources
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n) begin
      masked_sources_stage2 <= 8'b0;
    end else begin
      masked_sources_stage2 <= reset_sources_stage1 & enable_mask_stage1;
    end
  end

  // Stage 3: Register reset_status_stage3
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n) begin
      reset_status_stage3 <= 8'b0;
    end else begin
      reset_status_stage3 <= masked_sources_stage2;
    end
  end

  // Stage 3: Register system_reset_stage3
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n) begin
      system_reset_stage3 <= 1'b0;
    end else begin
      system_reset_stage3 <= |masked_sources_stage2;
    end
  end

  // Output: reset_status
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n) begin
      reset_status <= 8'b0;
    end else begin
      reset_status <= reset_status_stage3;
    end
  end

  // Output: system_reset
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n) begin
      system_reset <= 1'b0;
    end else begin
      system_reset <= system_reset_stage3;
    end
  end

endmodule