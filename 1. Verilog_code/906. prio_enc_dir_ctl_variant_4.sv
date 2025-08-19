//SystemVerilog
module prio_enc_dir_ctl #(parameter N=8)(
  input clk, rst_n, dir, // 0:LSB-first 1:MSB-first
  input valid_in,
  input [N-1:0] req,
  output reg [$clog2(N)-1:0] index,
  output reg valid_out
);

  // Stage 1: Request capture and initial processing
  reg [N-1:0] req_stage1;
  reg dir_stage1;
  reg valid_stage1;
  
  // Stage 2: Priority resolution
  reg [N-1:0] req_stage2;
  reg dir_stage2;
  reg valid_stage2;
  reg [$clog2(N)-1:0] index_stage2_msb;
  reg [$clog2(N)-1:0] index_stage2_lsb;
  reg msb_valid_stage2;
  reg lsb_valid_stage2;
  
  // Stage 1: Capture inputs
  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      req_stage1 <= 0;
      dir_stage1 <= 0;
      valid_stage1 <= 0;
    end else begin
      req_stage1 <= req;
      dir_stage1 <= dir;
      valid_stage1 <= valid_in;
    end
  end
  
  // Optimized MSB/LSB priority implementation
  reg [N-1:0] one_hot_msb;
  reg [N-1:0] one_hot_lsb;
  
  always @(*) begin
    one_hot_msb = req_stage1 & (~req_stage1 + 1); // Isolate rightmost 1
    one_hot_lsb = req_stage1 & (~(req_stage1 - 1)); // Isolate leftmost 1
  end
  
  // Priority encoder stage 2
  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      req_stage2 <= 0;
      dir_stage2 <= 0;
      valid_stage2 <= 0;
      index_stage2_msb <= 0;
      index_stage2_lsb <= 0;
      msb_valid_stage2 <= 0;
      lsb_valid_stage2 <= 0;
    end else begin
      req_stage2 <= req_stage1;
      dir_stage2 <= dir_stage1;
      valid_stage2 <= valid_stage1;
      
      // MSB priority encoding using optimized approach
      msb_valid_stage2 <= |req_stage1;
      index_stage2_msb <= 0;
      
      // LSB priority encoding using optimized approach  
      lsb_valid_stage2 <= |req_stage1;
      index_stage2_lsb <= 0;
      
      // One-hot to binary conversion
      if (|req_stage1) begin
        casez (one_hot_msb)
          // Priority encoding for MSB - more efficient implementation
          8'b1???????: index_stage2_msb <= 7;
          8'b01??????: index_stage2_msb <= 6;
          8'b001?????: index_stage2_msb <= 5;
          8'b0001????: index_stage2_msb <= 4;
          8'b00001???: index_stage2_msb <= 3;
          8'b000001??: index_stage2_msb <= 2;
          8'b0000001?: index_stage2_msb <= 1;
          8'b00000001: index_stage2_msb <= 0;
          default: index_stage2_msb <= 0;
        endcase
        
        casez (one_hot_lsb)
          // Priority encoding for LSB - more efficient implementation
          8'b???????1: index_stage2_lsb <= 0;
          8'b??????10: index_stage2_lsb <= 1;
          8'b?????100: index_stage2_lsb <= 2;
          8'b????1000: index_stage2_lsb <= 3;
          8'b???10000: index_stage2_lsb <= 4;
          8'b??100000: index_stage2_lsb <= 5;
          8'b?1000000: index_stage2_lsb <= 6;
          8'b10000000: index_stage2_lsb <= 7;
          default: index_stage2_lsb <= 0;
        endcase
      end
    end
  end
  
  // Stage 3: Final output selection - simplified logic
  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      index <= 0;
      valid_out <= 0;
    end else begin
      valid_out <= valid_stage2;
      if (valid_stage2) begin
        // Use direct mux instead of conditional branching
        index <= dir_stage2 ? index_stage2_msb : index_stage2_lsb;
      end
    end
  end
  
endmodule