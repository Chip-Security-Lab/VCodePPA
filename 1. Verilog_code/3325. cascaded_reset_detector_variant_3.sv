//SystemVerilog
module cascaded_reset_detector(
  input  wire        clk,
  input  wire        rst_n,
  input  wire [3:0]  reset_triggers, // Active high
  input  wire [3:0]  stage_enables,
  output reg  [3:0]  stage_resets,
  output reg         system_reset
);

  reg [3:0] stage_status;

  wire [3:0] enabled_triggers;
  assign enabled_triggers = reset_triggers & stage_enables;

  wire [3:0] next_stage_status;

  // Optimized cascaded logic using parallel prefix structure
  assign next_stage_status[0] = enabled_triggers[0];
  assign next_stage_status[1] = enabled_triggers[1] | next_stage_status[0] & stage_enables[1];
  assign next_stage_status[2] = enabled_triggers[2] | next_stage_status[1] & stage_enables[2];
  assign next_stage_status[3] = enabled_triggers[3] | next_stage_status[2] & stage_enables[3];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage_status   <= 4'b0000;
      stage_resets   <= 4'b0000;
      system_reset   <= 1'b0;
    end else begin
      stage_status   <= next_stage_status;
      stage_resets   <= next_stage_status;
      system_reset   <= |next_stage_status;
    end
  end

endmodule