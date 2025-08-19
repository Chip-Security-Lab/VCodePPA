module fixed_priority_intr_ctrl(
  input wire clk, rst_n,
  input wire [7:0] intr_src,
  output reg [2:0] intr_id,
  output reg intr_valid
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 3'b0; intr_valid <= 1'b0;
    end else begin
      intr_valid <= |intr_src;
      if (intr_src[7]) intr_id <= 3'd7;
      else if (intr_src[6]) intr_id <= 3'd6;
      else if (intr_src[5]) intr_id <= 3'd5;
      else if (intr_src[4]) intr_id <= 3'd4;
      else if (intr_src[3]) intr_id <= 3'd3;
      else if (intr_src[2]) intr_id <= 3'd2;
      else if (intr_src[1]) intr_id <= 3'd1;
      else if (intr_src[0]) intr_id <= 3'd0;
    end
  end
endmodule