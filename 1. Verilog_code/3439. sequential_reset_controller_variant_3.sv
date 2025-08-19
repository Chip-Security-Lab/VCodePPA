//SystemVerilog
module sequential_reset_controller (
  input wire clk,
  input wire rst_trigger,
  output reg [3:0] rst_vector
);
  // Pipeline stages
  localparam IDLE = 2'b00, RESET = 2'b01, RELEASE = 2'b10;
  
  // State and control signals
  reg [1:0] state, state_pipe;
  reg [2:0] step, step_pipe;
  reg valid, valid_pipe;
  
  // Pipeline registers for control path
  reg [1:0] next_state, next_state_reg;
  reg [2:0] next_step, next_step_reg;
  reg next_valid, next_valid_reg;
  
  // Input trigger registration and pipeline
  reg rst_trigger_reg, rst_trigger_pipe;
  
  // Reset vector computation registers
  reg [3:0] computed_rst_vector, computed_rst_vector_reg;
  reg [3:0] computed_rst_vector_stage1;
  
  // Stage 1: Register input signals for better timing
  always @(posedge clk) begin
    rst_trigger_reg <= rst_trigger;
    state_pipe <= state;
    step_pipe <= step;
    valid_pipe <= valid;
  end
  
  // Stage 2: Pre-compute next state logic part 1
  always @(*) begin
    // Default assignments
    next_state = state_pipe;
    next_step = step_pipe;
    next_valid = 1'b0;
    
    case (state_pipe)
      IDLE: begin
        if (rst_trigger_reg) begin
          next_state = RESET;
          next_step = 3'd0;
          next_valid = 1'b1;
        end
      end
      
      RESET: begin
        next_valid = 1'b1;
        if (step_pipe < 3'd4) begin
          next_step = step_pipe + 3'd1;
        end else begin
          next_state = RELEASE;
          next_step = 3'd0;
        end
      end
      
      RELEASE: begin
        if (step_pipe < 3'd4) begin
          next_step = step_pipe + 3'd1;
          next_valid = 1'b1;
        end else begin
          next_state = IDLE;
          next_valid = 1'b0;
        end
      end
      
      default: begin
        next_state = IDLE;
        next_valid = 1'b0;
      end
    endcase
  end
  
  // Stage 3: Pipeline next state computation
  always @(posedge clk) begin
    next_state_reg <= next_state;
    next_step_reg <= next_step;
    next_valid_reg <= next_valid;
  end
  
  // Stage 4: Update state registers
  always @(posedge clk) begin
    state <= next_state_reg;
    step <= next_step_reg;
    valid <= next_valid_reg;
  end
  
  // Pre-compute reset vector stage 1 (basic logic)
  always @(*) begin
    if (state_pipe == RESET) begin
      computed_rst_vector_stage1 = 4'b1111;
    end else begin
      computed_rst_vector_stage1 = rst_vector;
    end
  end
  
  // Pipeline register for reset vector computation intermediate result
  always @(posedge clk) begin
    computed_rst_vector_stage1 <= computed_rst_vector_stage1;
  end
  
  // Pre-compute reset vector stage 2 (further logic with pipelined input)
  always @(*) begin
    computed_rst_vector = computed_rst_vector_stage1;
    
    if (state_pipe == RELEASE && step_pipe > 3'd0 && step_pipe <= 3'd4) begin
      computed_rst_vector[step_pipe-1] = 1'b0;
    end
  end
  
  // Pipeline register for reset vector final computation
  always @(posedge clk) begin
    computed_rst_vector_reg <= computed_rst_vector;
  end
  
  // Final output stage
  always @(posedge clk) begin
    if (valid_pipe) begin
      rst_vector <= computed_rst_vector_reg;
    end
  end
endmodule