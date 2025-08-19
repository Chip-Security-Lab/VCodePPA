//SystemVerilog
module delayed_reset_release #(
  parameter DELAY_CYCLES = 12
) (
  input  wire clk,
  input  wire reset_in,
  output reg  reset_out
);
  localparam PIPE_STAGES = 4;
  localparam STAGE_DELAY = (DELAY_CYCLES + PIPE_STAGES - 1) / PIPE_STAGES;
  
  // Pipeline stage registers
  reg [PIPE_STAGES-1:0] reset_pipe;
  reg [$clog2(STAGE_DELAY):0] stage_counters [PIPE_STAGES-1:0];
  reg [PIPE_STAGES-1:0] stage_active;
  
  integer i;
  
  always @(posedge clk) begin
    // First pipeline stage
    if (reset_in) begin
      reset_pipe[0] <= 1'b1;
      stage_counters[0] <= STAGE_DELAY;
      stage_active[0] <= 1'b1;
    end else if (stage_active[0] && stage_counters[0] > 0) begin
      reset_pipe[0] <= 1'b1;
      stage_counters[0] <= stage_counters[0] - 1'b1;
      stage_active[0] <= 1'b1;
    end else begin
      reset_pipe[0] <= 1'b0;
      stage_active[0] <= 1'b0;
    end
    
    // Propagate through pipeline stages
    for (i = 1; i < PIPE_STAGES; i = i + 1) begin
      if (reset_in) begin
        reset_pipe[i] <= 1'b1;
        stage_counters[i] <= STAGE_DELAY;
        stage_active[i] <= 1'b0;
      end else if (reset_pipe[i-1] && !stage_active[i] && !stage_active[i-1]) begin
        // Handoff from previous stage
        reset_pipe[i] <= 1'b1;
        stage_counters[i] <= STAGE_DELAY;
        stage_active[i] <= 1'b1;
      end else if (stage_active[i] && stage_counters[i] > 0) begin
        reset_pipe[i] <= 1'b1;
        stage_counters[i] <= stage_counters[i] - 1'b1;
        stage_active[i] <= 1'b1;
      end else begin
        reset_pipe[i] <= 1'b0;
        stage_active[i] <= 1'b0;
      end
    end
    
    // Output stage
    reset_out <= |reset_pipe;
  end
endmodule