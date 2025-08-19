module fsm_priority_intr_ctrl(
  input clk, rst_n,
  input [7:0] intr,
  input ack,
  output reg [2:0] intr_id,
  output reg intr_active
);
  reg [1:0] state, next_state;
  parameter IDLE = 2'b00, DETECT = 2'b01, SERVE = 2'b10, CLEAR = 2'b11;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= next_state;
  end
  
  always @(*) begin
    next_state = state;
    case (state)
      IDLE: if (|intr) next_state = DETECT;
      DETECT: next_state = SERVE;
      SERVE: if (ack) next_state = CLEAR;
      CLEAR: next_state = IDLE;
    endcase
  end
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 3'b0; intr_active <= 1'b0;
    end else if (state == DETECT) begin
      intr_active <= 1'b1;
      casez (intr)
        8'b1???????: intr_id <= 3'd7;
        8'b01??????: intr_id <= 3'd6;
        8'b001?????: intr_id <= 3'd5;
        8'b0001????: intr_id <= 3'd4;
        8'b00001???: intr_id <= 3'd3;
        8'b000001??: intr_id <= 3'd2;
        8'b0000001?: intr_id <= 3'd1;
        8'b00000001: intr_id <= 3'd0;
        default: intr_id <= 3'd0;
      endcase
    end else if (state == CLEAR) begin
      intr_active <= 1'b0;
    end
  end
endmodule