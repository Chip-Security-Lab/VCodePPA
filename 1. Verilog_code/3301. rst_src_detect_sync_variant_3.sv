//SystemVerilog
// SystemVerilog
module rst_src_detect_sync_pipeline(
  input  wire         clk,
  input  wire         rst_n,
  input  wire         por_n,
  input  wire         wdt_n,
  input  wire         ext_n,
  input  wire         sw_n,
  output reg  [3:0]   rst_src,
  output reg          valid_out,
  input  wire         flush
);

  // Stage 1: Input sampling
  reg por_sampled_stage1, wdt_sampled_stage1, ext_sampled_stage1, sw_sampled_stage1;
  reg valid_stage1;

  // Stage 2: Inversion
  reg por_inv_stage2, wdt_inv_stage2, ext_inv_stage2, sw_inv_stage2;
  reg valid_stage2;

  // Stage 3: Registered outputs
  reg por_inv_stage3, wdt_inv_stage3, ext_inv_stage3, sw_inv_stage3;
  reg valid_stage3;

  // Stage 1: Input sampling
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      por_sampled_stage1 <= 1'b1;
      wdt_sampled_stage1 <= 1'b1;
      ext_sampled_stage1 <= 1'b1;
      sw_sampled_stage1  <= 1'b1;
      valid_stage1       <= 1'b0;
    end else if (flush) begin
      por_sampled_stage1 <= 1'b1;
      wdt_sampled_stage1 <= 1'b1;
      ext_sampled_stage1 <= 1'b1;
      sw_sampled_stage1  <= 1'b1;
      valid_stage1       <= 1'b0;
    end else begin
      por_sampled_stage1 <= por_n;
      wdt_sampled_stage1 <= wdt_n;
      ext_sampled_stage1 <= ext_n;
      sw_sampled_stage1  <= sw_n;
      valid_stage1       <= 1'b1;
    end
  end

  // Stage 2: Inversion
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      por_inv_stage2 <= 1'b0;
      wdt_inv_stage2 <= 1'b0;
      ext_inv_stage2 <= 1'b0;
      sw_inv_stage2  <= 1'b0;
      valid_stage2   <= 1'b0;
    end else if (flush) begin
      por_inv_stage2 <= 1'b0;
      wdt_inv_stage2 <= 1'b0;
      ext_inv_stage2 <= 1'b0;
      sw_inv_stage2  <= 1'b0;
      valid_stage2   <= 1'b0;
    end else begin
      por_inv_stage2 <= ~por_sampled_stage1;
      wdt_inv_stage2 <= ~wdt_sampled_stage1;
      ext_inv_stage2 <= ~ext_sampled_stage1;
      sw_inv_stage2  <= ~sw_sampled_stage1;
      valid_stage2   <= valid_stage1;
    end
  end

  // Stage 3: Registered outputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      por_inv_stage3 <= 1'b0;
      wdt_inv_stage3 <= 1'b0;
      ext_inv_stage3 <= 1'b0;
      sw_inv_stage3  <= 1'b0;
      valid_stage3   <= 1'b0;
    end else if (flush) begin
      por_inv_stage3 <= 1'b0;
      wdt_inv_stage3 <= 1'b0;
      ext_inv_stage3 <= 1'b0;
      sw_inv_stage3  <= 1'b0;
      valid_stage3   <= 1'b0;
    end else begin
      por_inv_stage3 <= por_inv_stage2;
      wdt_inv_stage3 <= wdt_inv_stage2;
      ext_inv_stage3 <= ext_inv_stage2;
      sw_inv_stage3  <= sw_inv_stage2;
      valid_stage3   <= valid_stage2;
    end
  end

  // Output stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rst_src   <= 4'b0000;
      valid_out <= 1'b0;
    end else if (flush) begin
      rst_src   <= 4'b0000;
      valid_out <= 1'b0;
    end else begin
      rst_src[0] <= por_inv_stage3;
      rst_src[1] <= wdt_inv_stage3;
      rst_src[2] <= ext_inv_stage3;
      rst_src[3] <= sw_inv_stage3;
      valid_out  <= valid_stage3;
    end
  end

endmodule