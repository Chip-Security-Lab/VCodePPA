//SystemVerilog
module RD10 #(parameter BITS=8)(
  input clk, 
  input rst, 
  input en,
  input [BITS-1:0] in_val,
  output reg [BITS-1:0] out_val,
  
  // Pipeline control signals
  input pipe_valid_in,
  output reg pipe_valid_out,
  input pipe_ready_in,
  output reg pipe_ready_out
);

  // Pipeline stage registers
  reg [BITS-1:0] stage1_val;
  reg stage1_valid;
  reg [BITS-1:0] stage2_val;
  reg stage2_valid;
  
  // Ready signals propagation (backward) - combinational logic
  always @(*) begin
    pipe_ready_out = pipe_ready_in || !stage1_valid;
  end
  
  // Sequential logic - merged always blocks with same clock domain
  always @(posedge clk) begin
    if (rst) begin
      // Reset all registers
      stage1_val <= 0;
      stage1_valid <= 0;
      stage2_val <= 0;
      stage2_valid <= 0;
      out_val <= 0;
      pipe_valid_out <= 0;
    end
    else begin
      // Stage 1 logic
      if (pipe_ready_out && pipe_valid_in) begin
        stage1_val <= en ? in_val : 0;
        stage1_valid <= 1;
      end
      else if (pipe_ready_in) begin
        stage1_valid <= 0;
      end
      
      // Stage 2 logic
      if (pipe_ready_in) begin
        if (stage1_valid) begin
          stage2_val <= stage1_val;
          stage2_valid <= 1;
          out_val <= stage1_val;
          pipe_valid_out <= 1;
        end
        else begin
          stage2_valid <= 0;
          pipe_valid_out <= 0;
        end
      end
    end
  end

endmodule