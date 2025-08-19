//SystemVerilog
module prio_enc_dir_ctl #(parameter N=8)(
  input clk,
  input dir, // 0:LSB-first 1:MSB-first
  input [N-1:0] req,
  output reg [$clog2(N)-1:0] index
);
  
  // Pre-encoded results for both directions
  reg [$clog2(N)-1:0] msb_index, lsb_index;
  reg msb_valid, lsb_valid;
  reg [N-1:0] req_reg;
  reg dir_reg;
  
  // Stage 1: Register inputs and compute both encodings in parallel
  always @(posedge clk) begin
    req_reg <= req;
    dir_reg <= dir;
  end
  
  // Stage 2: MSB-first priority detection logic
  always @(posedge clk) begin
    msb_valid <= 0;
    msb_index <= 0;
    
    for (integer i = N-1; i >= 0; i = i-1) begin
      if (req_reg[i] && !msb_valid) begin
        msb_index <= i[$clog2(N)-1:0];
        msb_valid <= 1;
      end
    end
  end
  
  // Stage 2: LSB-first priority detection logic (parallel to MSB)
  always @(posedge clk) begin
    lsb_valid <= 0;
    lsb_index <= 0;
    
    for (integer i = 0; i < N; i = i+1) begin
      if (req_reg[i] && !lsb_valid) begin
        lsb_index <= i[$clog2(N)-1:0];
        lsb_valid <= 1;
      end
    end
  end
  
  // Stage 3: Output selection based on direction
  always @(posedge clk) begin
    if (dir_reg)
      index <= msb_index;
    else
      index <= lsb_index;
  end

endmodule