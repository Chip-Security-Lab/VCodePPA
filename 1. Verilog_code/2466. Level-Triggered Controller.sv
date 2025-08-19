module level_triggered_intr_ctrl(
  input wire clock, reset_n,
  input wire [3:0] intr_level,
  input wire [3:0] intr_enable,
  output reg [1:0] intr_id,
  output reg intr_out
);
  reg [3:0] level_detect;
  
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      level_detect <= 4'h0;
      intr_id <= 2'h0;
      intr_out <= 1'b0;
    end else begin
      level_detect <= intr_level & intr_enable;
      intr_out <= |level_detect;
      
      casez (level_detect)
        4'b???1: intr_id <= 2'd0;
        4'b??10: intr_id <= 2'd1;
        4'b?100: intr_id <= 2'd2;
        4'b1000: intr_id <= 2'd3;
        default: intr_id <= 2'd0;
      endcase
    end
  end
endmodule