//SystemVerilog
//===========================================================================
// Module: sequential_reset_controller
// Description: Top-level controller for sequential reset management
// Standard: IEEE 1364-2005
//===========================================================================
module sequential_reset_controller (
  input  wire       clk,
  input  wire       rst_trigger,
  output wire [3:0] rst_vector
);

  // Interface signals between submodules
  wire [1:0]  fsm_state;
  wire [2:0]  step_counter;
  wire        load_counter;
  wire        inc_counter;
  wire        clear_counter;
  wire        load_rst_vector;
  wire        clear_rst_bit;

  // State machine controller submodule
  fsm_controller u_fsm_controller (
    .clk           (clk),
    .rst_trigger   (rst_trigger),
    .step_counter  (step_counter),
    .fsm_state     (fsm_state),
    .load_counter  (load_counter),
    .inc_counter   (inc_counter),
    .clear_counter (clear_counter),
    .load_rst_vector (load_rst_vector),
    .clear_rst_bit (clear_rst_bit)
  );

  // Step counter submodule
  step_counter u_step_counter (
    .clk           (clk),
    .load_counter  (load_counter),
    .inc_counter   (inc_counter),
    .clear_counter (clear_counter),
    .step_counter  (step_counter)
  );

  // Reset vector manager submodule
  reset_vector_manager u_reset_vector_manager (
    .clk             (clk),
    .load_rst_vector (load_rst_vector),
    .clear_rst_bit   (clear_rst_bit),
    .step_counter    (step_counter),
    .rst_vector      (rst_vector)
  );

endmodule

//===========================================================================
// Module: fsm_controller
// Description: Implements the state machine logic
//===========================================================================
module fsm_controller (
  input  wire       clk,
  input  wire       rst_trigger,
  input  wire [2:0] step_counter,
  output reg  [1:0] fsm_state,
  output reg        load_counter,
  output reg        inc_counter,
  output reg        clear_counter,
  output reg        load_rst_vector,
  output reg        clear_rst_bit
);

  // State encoding
  localparam IDLE    = 2'b00;
  localparam RESET   = 2'b01;
  localparam RELEASE = 2'b10;
  
  // Control signals - pre-registered combinational logic
  wire load_counter_next   = (fsm_state == IDLE) && rst_trigger;
  wire inc_counter_next    = ((fsm_state == RESET && step_counter < 3'd4) || 
                           (fsm_state == RELEASE && step_counter < 3'd4));
  wire clear_counter_next  = ((fsm_state == RESET && step_counter >= 3'd4) || 
                           (fsm_state == RELEASE && step_counter >= 3'd4));
  wire load_rst_vector_next = (fsm_state == IDLE) && rst_trigger;
  wire clear_rst_bit_next   = (fsm_state == RELEASE && step_counter < 3'd4);
  
  // Next state determination - pre-registered
  reg [1:0] fsm_state_next;
  
  always @(*) begin
    case (fsm_state)
      IDLE: 
        if (rst_trigger) begin
          fsm_state_next = RESET;
        end else begin
          fsm_state_next = IDLE;
        end
      
      RESET: 
        if (step_counter >= 3'd4) begin
          fsm_state_next = RELEASE;
        end else begin
          fsm_state_next = RESET;
        end
      
      RELEASE: 
        if (step_counter >= 3'd4) begin
          fsm_state_next = IDLE;
        end else begin
          fsm_state_next = RELEASE;
        end
      
      default: 
        fsm_state_next = IDLE;
    endcase
  end

  // Register all control signals and state on clock edge
  always @(posedge clk) begin
    fsm_state <= fsm_state_next;
    load_counter <= load_counter_next;
    inc_counter <= inc_counter_next;
    clear_counter <= clear_counter_next;
    load_rst_vector <= load_rst_vector_next;
    clear_rst_bit <= clear_rst_bit_next;
  end

endmodule

//===========================================================================
// Module: step_counter
// Description: Manages the step counter for timing operations
//===========================================================================
module step_counter (
  input  wire       clk,
  input  wire       load_counter,
  input  wire       inc_counter,
  input  wire       clear_counter,
  output reg  [2:0] step_counter
);

  // Pre-registered combinational logic
  reg [2:0] step_counter_next;
  
  always @(*) begin
    if (load_counter || clear_counter) begin
      step_counter_next = 3'd0;
    end else if (inc_counter) begin
      step_counter_next = step_counter + 3'd1;
    end else begin
      step_counter_next = step_counter;
    end
  end
  
  // Register output on clock edge
  always @(posedge clk) begin
    step_counter <= step_counter_next;
  end

endmodule

//===========================================================================
// Module: reset_vector_manager
// Description: Controls the sequential reset vector outputs
//===========================================================================
module reset_vector_manager (
  input  wire       clk,
  input  wire       load_rst_vector,
  input  wire       clear_rst_bit,
  input  wire [2:0] step_counter,
  output reg  [3:0] rst_vector
);

  // Pre-registered combinational logic
  reg [3:0] rst_vector_next;
  
  always @(*) begin
    if (load_rst_vector) begin
      rst_vector_next = 4'b1111;
    end else if (clear_rst_bit) begin
      rst_vector_next = rst_vector;
      rst_vector_next[step_counter] = 1'b0;
    end else begin
      rst_vector_next = rst_vector;
    end
  end
  
  // Register output on clock edge
  always @(posedge clk) begin
    rst_vector <= rst_vector_next;
  end

endmodule