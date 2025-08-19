//SystemVerilog
module pipelined_parity_gen(
  input clk, rst_n,
  input [31:0] data_in,
  input valid_in,
  output reg ready_out,
  output reg parity_out,
  output reg valid_out,
  input ready_in
);

  // Pre-compute parity values in first stage
  reg [7:0] stage1_data_lo, stage1_data_hi;
  reg [7:0] stage1_data_lo_hi, stage1_data_hi_hi;
  reg stage1_valid;
  
  // Pre-computed parity values
  wire parity_lo_lo = ^data_in[7:0];
  wire parity_lo_hi = ^data_in[15:8];
  wire parity_hi_lo = ^data_in[23:16];
  wire parity_hi_hi = ^data_in[31:24];
  
  // Stage 2 registers - moved before combinational logic
  reg stage2_parity_lo_lo, stage2_parity_lo_hi;
  reg stage2_parity_hi_lo, stage2_parity_hi_hi;
  reg stage2_valid;
  
  // Stage 3 registers - moved before combinational logic
  reg stage3_parity_lo, stage3_parity_hi;
  reg stage3_valid;
  
  // Final stage
  reg stage4_valid;
  
  // Pipeline control
  wire stage1_ready, stage2_ready, stage3_ready;
  
  // Flow control logic
  assign stage3_ready = ready_in;
  assign stage2_ready = !stage3_valid || (stage3_valid && stage3_ready);
  assign stage1_ready = !stage2_valid || (stage2_valid && stage2_ready);
  
  // Pre-compute combined parity values
  wire next_stage3_parity_lo = stage2_parity_lo_lo ^ stage2_parity_lo_hi;
  wire next_stage3_parity_hi = stage2_parity_hi_lo ^ stage2_parity_hi_hi;
  wire next_parity_out = stage3_parity_lo ^ stage3_parity_hi;
  
  always @(posedge clk) begin
    if (!rst_n) begin
      // Reset all pipeline registers
      stage1_data_lo <= 8'b0;
      stage1_data_hi <= 8'b0;
      stage1_data_lo_hi <= 8'b0;
      stage1_data_hi_hi <= 8'b0;
      stage1_valid <= 1'b0;
      
      stage2_parity_lo_lo <= 1'b0;
      stage2_parity_lo_hi <= 1'b0;
      stage2_parity_hi_lo <= 1'b0;
      stage2_parity_hi_hi <= 1'b0;
      stage2_valid <= 1'b0;
      
      stage3_parity_lo <= 1'b0;
      stage3_parity_hi <= 1'b0;
      stage3_valid <= 1'b0;
      
      stage4_valid <= 1'b0;
      parity_out <= 1'b0;
      valid_out <= 1'b0;
      ready_out <= 1'b1;
    end else begin
      // Stage 1: Split 32-bit input into 4 chunks and pre-compute parity
      if (valid_in && ready_out) begin
        // Store pre-computed parity values directly
        stage2_parity_lo_lo <= parity_lo_lo;
        stage2_parity_lo_hi <= parity_lo_hi;
        stage2_parity_hi_lo <= parity_hi_lo;
        stage2_parity_hi_hi <= parity_hi_hi;
        stage1_valid <= 1'b1;
      end else if (stage1_ready) begin
        stage1_valid <= 1'b0;
      end
      
      // Stage 2: Register holds parity values from Stage 1
      if (stage1_valid && stage1_ready) begin
        // Register pre-calculated stage 3 values
        stage3_parity_lo <= next_stage3_parity_lo;
        stage3_parity_hi <= next_stage3_parity_hi;
        stage2_valid <= 1'b1;
      end else if (stage2_ready) begin
        stage2_valid <= 1'b0;
      end
      
      // Stage 3: Register holds combined parity values from Stage 2
      if (stage2_valid && stage2_ready) begin
        // Register pre-calculated final parity output
        parity_out <= next_parity_out;
        stage3_valid <= 1'b1;
      end else if (stage3_ready) begin
        stage3_valid <= 1'b0;
      end
      
      // Final stage: Output valid signal
      if (stage3_valid && stage3_ready) begin
        stage4_valid <= 1'b1;
      end else if (ready_in) begin
        stage4_valid <= 1'b0;
      end
      
      // Valid signal propagation
      valid_out <= stage4_valid;
      
      // Ready signal generation
      ready_out <= !stage1_valid || (stage1_valid && stage1_ready);
    end
  end
endmodule