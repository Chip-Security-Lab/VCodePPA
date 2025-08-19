module weighted_priority_intr_ctrl(
  input [7:0] interrupts,
  input [15:0] weights, // 2 bits per interrupt source
  output [2:0] priority_id,
  output valid
);
  reg [2:0] highest_id;
  reg [1:0] highest_weight;
  reg found;
  integer i;
  
  always @(*) begin
    highest_id = 3'd0; highest_weight = 2'd0; found = 1'b0;
    for (i = 0; i < 8; i = i + 1) begin
      if (interrupts[i] && (weights[i*2+:2] > highest_weight)) begin
        highest_id = i; highest_weight = weights[i*2+:2]; found = 1'b1;
      end
    end
  end
  
  assign priority_id = highest_id;
  assign valid = found;
endmodule