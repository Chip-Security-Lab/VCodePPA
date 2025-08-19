//SystemVerilog
module moore_4state_shift_ctrl_pipelined #(parameter COUNT_WIDTH = 4)(
  input  clk,
  input  rst,
  input  start,
  input  [COUNT_WIDTH-1:0] shift_count,
  output reg shift_en,
  output reg done
);

  // Pipeline stage registers
  reg [1:0] state_stage1, state_stage2, state_stage3;
  reg [COUNT_WIDTH-1:0] counter_stage1, counter_stage2;
  reg start_stage1, start_stage2;
  reg [COUNT_WIDTH-1:0] shift_count_stage1;
  
  localparam WAIT  = 2'b00,
             LOAD  = 2'b01, 
             SHIFT = 2'b10,
             DONE_ST = 2'b11;

  // Stage 1: Input registration and state transition
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= WAIT;
      start_stage1 <= 1'b0;
      shift_count_stage1 <= 0;
    end else begin
      start_stage1 <= start;
      shift_count_stage1 <= shift_count;
      
      case (state_stage1)
        WAIT: state_stage1 <= start ? LOAD : WAIT;
        LOAD: state_stage1 <= SHIFT;
        SHIFT: state_stage1 <= (counter_stage1 == 1) ? DONE_ST : SHIFT;
        DONE_ST: state_stage1 <= WAIT;
      endcase
    end
  end

  // Stage 2: Counter logic
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      counter_stage1 <= 0;
      state_stage2 <= WAIT;
      start_stage2 <= 1'b0;
    end else begin
      state_stage2 <= state_stage1;
      start_stage2 <= start_stage1;
      
      if (state_stage1 == LOAD)
        counter_stage1 <= shift_count_stage1;
      else if (state_stage1 == SHIFT && counter_stage1 > 0)
        counter_stage1 <= counter_stage1 - 1;
    end
  end

  // Stage 3: Output generation
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage3 <= WAIT;
      counter_stage2 <= 0;
      shift_en <= 1'b0;
      done <= 1'b0;
    end else begin
      state_stage3 <= state_stage2;
      counter_stage2 <= counter_stage1;
      
      case (state_stage2)
        SHIFT: begin
          shift_en <= 1'b1;
          done <= 1'b0;
        end
        DONE_ST: begin
          shift_en <= 1'b0;
          done <= 1'b1;
        end
        default: begin
          shift_en <= 1'b0;
          done <= 1'b0;
        end
      endcase
    end
  end

endmodule