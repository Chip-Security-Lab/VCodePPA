//SystemVerilog
//IEEE 1364-2005 Verilog
module reset_sync_mem_wr (
  input  wire        clk,      // Clock input
  input  wire        rst_n,    // Active-low asynchronous reset
  input  wire        wr_valid, // Valid signal from sender
  output wire        wr_ready, // Ready signal to sender
  input  wire        wr_data,  // Write data input
  output wire        mem_valid, // Valid signal to receiver
  input  wire        mem_ready, // Ready signal from receiver
  output reg         mem_out   // Memory output
);

  // Pipeline registers for deeper synchronization
  reg stage1_reg, stage1_valid;
  reg stage2_reg, stage2_valid;
  reg stage3_reg, stage3_valid;
  reg stage4_reg, stage4_valid;
  
  // Flow control signals
  reg pipeline_stall;
  
  // Back-pressure handling
  assign wr_ready = !pipeline_stall;
  assign mem_valid = stage4_valid;
  
  // Pipeline stall logic - stall when receiver is not ready
  always @(*) begin
    pipeline_stall = stage4_valid && !mem_ready;
  end

  // Reset synchronizer with deeper pipeline implementation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Parallel reset implementation for better timing
      stage1_reg <= 1'b0;
      stage2_reg <= 1'b0;
      stage3_reg <= 1'b0;
      stage4_reg <= 1'b0;
      mem_out <= 1'b0;
      
      // Reset valid flags
      stage1_valid <= 1'b0;
      stage2_valid <= 1'b0;
      stage3_valid <= 1'b0;
      stage4_valid <= 1'b0;
    end 
    else begin
      if (!pipeline_stall) begin
        // Stage 1: Accept new data when valid and ready
        stage1_reg <= wr_valid ? wr_data : stage1_reg;
        stage1_valid <= wr_valid;
        
        // Forward data through pipeline
        stage2_reg <= stage1_reg;
        stage2_valid <= stage1_valid;
        
        stage3_reg <= stage2_reg;
        stage3_valid <= stage2_valid;
        
        stage4_reg <= stage3_reg;
        stage4_valid <= stage3_valid;
        
        // Output stage: Update only when receiver is ready
        if (mem_ready || !stage4_valid) begin
          mem_out <= stage4_reg;
        end
      end
    end
  end

endmodule