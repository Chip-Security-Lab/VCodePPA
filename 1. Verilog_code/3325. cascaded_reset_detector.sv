module cascaded_reset_detector(
  input clk, rst_n,
  input [3:0] reset_triggers, // Active high
  input [3:0] stage_enables,
  output reg [3:0] stage_resets,
  output reg system_reset
);
  reg [3:0] stage_status = 4'b0000;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage_status <= 4'b0000;
      stage_resets <= 4'b0000;
      system_reset <= 1'b0;
    end else begin
      // Stage 1: Direct reset inputs
      stage_status[0] <= reset_triggers[0] & stage_enables[0];
      
      // Stage 2: Depends on stage 1
      stage_status[1] <= (reset_triggers[1] | stage_status[0]) & stage_enables[1];
      
      // Stage 3: Depends on stage 2
      stage_status[2] <= (reset_triggers[2] | stage_status[1]) & stage_enables[2];
      
      // Stage 4: Depends on stage 3
      stage_status[3] <= (reset_triggers[3] | stage_status[2]) & stage_enables[3];
      
      stage_resets <= stage_status;
      system_reset <= |stage_status;
    end
  end
endmodule