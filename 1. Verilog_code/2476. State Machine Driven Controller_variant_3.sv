//SystemVerilog
module fsm_priority_intr_ctrl(
  input clk, rst_n,
  input [7:0] intr,
  input ack,
  output reg [2:0] intr_id,
  output reg req
);
  
  // Pipeline stage parameters
  parameter IDLE = 2'b00, DETECT = 2'b01, SERVE = 2'b10, CLEAR = 2'b11;
  
  // Pipeline control signals
  reg [1:0] state, next_state;
  
  // Pipeline registers
  reg [7:0] intr_stage1;
  reg valid_stage1, valid_stage2;
  reg [2:0] intr_id_stage1;
  
  // Pipeline stage 1: Input capture and detect interrupts
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_stage1 <= 8'b0;
      valid_stage1 <= 1'b0;
    end else begin
      intr_stage1 <= intr;
      valid_stage1 <= (state == IDLE) && (|intr);
    end
  end
  
  // Pipeline stage 2: Priority encoding
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id_stage1 <= 3'b0;
      valid_stage2 <= 1'b0;
    end else begin
      valid_stage2 <= valid_stage1;
      if (valid_stage1) begin
        casez (intr_stage1)
          8'b1???????: intr_id_stage1 <= 3'd7;
          8'b01??????: intr_id_stage1 <= 3'd6;
          8'b001?????: intr_id_stage1 <= 3'd5;
          8'b0001????: intr_id_stage1 <= 3'd4;
          8'b00001???: intr_id_stage1 <= 3'd3;
          8'b000001??: intr_id_stage1 <= 3'd2;
          8'b0000001?: intr_id_stage1 <= 3'd1;
          8'b00000001: intr_id_stage1 <= 3'd0;
          default:     intr_id_stage1 <= 3'd0;
        endcase
      end
    end
  end
  
  // FSM for pipeline control
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= next_state;
  end
  
  // FSM state transition logic
  always @(*) begin
    next_state = state;
    case (state)
      IDLE:   if (|intr) next_state = DETECT;
      DETECT: next_state = SERVE;
      SERVE:  if (ack) next_state = CLEAR;
      CLEAR:  next_state = IDLE;
    endcase
  end
  
  // Output stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= 3'b0;
      req <= 1'b0;
    end else begin
      if (valid_stage2 && state == DETECT) begin
        intr_id <= intr_id_stage1;
        req <= 1'b1;
      end else if (state == CLEAR) begin
        req <= 1'b0;
      end
    end
  end

endmodule