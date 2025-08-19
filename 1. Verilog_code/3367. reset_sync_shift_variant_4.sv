//SystemVerilog
module reset_sync_shift #(
  parameter DEPTH = 3
)(
  input  wire clk,     // Clock input
  input  wire rst_n,   // Active-low asynchronous reset
  output wire sync_out // Synchronized reset output
);

  // Pipeline stage registers
  reg [DEPTH-1:0] pipeline_stages;
  
  // Pipeline valid flags with one-hot encoding for better timing
  reg [DEPTH:0] stage_valid;
  
  // Pipeline control signals
  wire stage_ready;
  
  // First stage initialization
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pipeline_stages[0] <= 1'b0;
      stage_valid[0] <= 1'b1; // Valid bit for input stage
      stage_valid[1] <= 1'b0; // Valid bit for first pipeline stage
    end
    else begin
      pipeline_stages[0] <= 1'b1;
      stage_valid[1] <= stage_valid[0] & stage_ready;
    end
  end
  
  // Remaining pipeline stages with balanced logic
  genvar i;
  generate
    for (i = 1; i < DEPTH; i = i + 1) begin : gen_pipeline_stages
      always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          pipeline_stages[i] <= 1'b0;
          stage_valid[i+1] <= 1'b0;
        end
        else if (stage_valid[i] & stage_ready) begin
          pipeline_stages[i] <= pipeline_stages[i-1];
          stage_valid[i+1] <= stage_valid[i];
        end
      end
    end
  endgenerate
  
  // Pipelined output logic with handshaking
  assign stage_ready = 1'b1; // Always ready in this implementation
  assign sync_out = pipeline_stages[DEPTH-1] & stage_valid[DEPTH];
  
  // Performance counters for pipeline utilization
  // synthesis translate_off
  reg [31:0] pipeline_bubbles;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      pipeline_bubbles <= 32'h0;
    else if (!(|stage_valid[DEPTH:1]))
      pipeline_bubbles <= pipeline_bubbles + 1'b1;
  end
  // synthesis translate_on
  
endmodule