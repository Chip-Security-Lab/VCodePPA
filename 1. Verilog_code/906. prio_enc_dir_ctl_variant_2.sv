//SystemVerilog
module prio_enc_dir_ctl #(parameter N=8)(
  input clk, 
  input rst_n,      // Added reset signal
  input dir,        // 0:LSB-first 1:MSB-first
  input [N-1:0] req,
  input valid_in,   // Added valid input signal
  output reg valid_out,
  output reg [$clog2(N)-1:0] index
);

  // Stage 1: Split request and direction handling
  reg [N-1:0] req_stage1;
  reg dir_stage1;
  reg valid_stage1;
  
  // Stage 2: Intermediate priority results for both directions
  reg [$clog2(N)-1:0] msb_index_stage2;
  reg [$clog2(N)-1:0] lsb_index_stage2;
  reg msb_valid_stage2, lsb_valid_stage2;
  reg dir_stage2;
  reg valid_stage2;
  
  // MSB priority encoder logic - stage 1 to 2
  integer i;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_stage1 <= 0;
      dir_stage1 <= 0;
      valid_stage1 <= 0;
    end else begin
      req_stage1 <= req;
      dir_stage1 <= dir;
      valid_stage1 <= valid_in;
    end
  end
  
  // Stage 2 logic - Calculate priority indices
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      msb_index_stage2 <= 0;
      lsb_index_stage2 <= 0;
      msb_valid_stage2 <= 0;
      lsb_valid_stage2 <= 0;
      dir_stage2 <= 0;
      valid_stage2 <= 0;
    end else begin
      dir_stage2 <= dir_stage1;
      valid_stage2 <= valid_stage1;
      
      // MSB priority encoder (working in parallel)
      msb_valid_stage2 <= 0;
      msb_index_stage2 <= 0;
      for (i = N-1; i >= 0; i = i-1) begin
        if (req_stage1[i] && !msb_valid_stage2) begin
          msb_index_stage2 <= i[$clog2(N)-1:0];
          msb_valid_stage2 <= 1;
        end
      end
      
      // LSB priority encoder (working in parallel)
      lsb_valid_stage2 <= 0;
      lsb_index_stage2 <= 0;
      for (i = 0; i < N; i = i+1) begin
        if (req_stage1[i] && !lsb_valid_stage2) begin
          lsb_index_stage2 <= i[$clog2(N)-1:0];
          lsb_valid_stage2 <= 1;
        end
      end
    end
  end
  
  // Stage 3 - Select output based on direction
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      index <= 0;
      valid_out <= 0;
    end else begin
      valid_out <= valid_stage2;
      if (dir_stage2)
        index <= msb_index_stage2;  // MSB first
      else
        index <= lsb_index_stage2;  // LSB first
    end
  end
  
endmodule