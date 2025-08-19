//SystemVerilog
module fsm_parity_gen(
  input clk, rst, start,
  input [15:0] data_in,
  output valid, 
  output parity_bit
);
  localparam IDLE = 2'b00, COMPUTE = 2'b01, DONE = 2'b10;
  
  wire [1:0] state;
  wire [3:0] bit_pos;
  wire compute_done;
  wire state_idle, state_compute, state_done;
  wire load_initial_values;
  wire update_bit_position;
  wire update_parity;
  
  // Pipeline stage 1: State decoding and control
  wire [1:0] state_stage1;
  wire state_idle_stage1, state_compute_stage1, state_done_stage1;
  wire load_initial_values_stage1;
  wire update_bit_position_stage1;
  wire update_parity_stage1;
  
  // Pipeline stage 2: Bit position calculation
  wire [3:0] bit_pos_stage2;
  wire compute_done_stage2;
  
  // Pipeline stage 3: Parity calculation
  wire parity_bit_stage3;
  
  // Stage 1: State decoder and control
  state_decoder u_state_decoder (
    .state(state_stage1),
    .state_idle(state_idle_stage1),
    .state_compute(state_compute_stage1),
    .state_done(state_done_stage1)
  );
  
  control_unit u_control_unit (
    .clk(clk),
    .rst(rst),
    .start(start),
    .compute_done(compute_done_stage2),
    .state_idle(state_idle_stage1),
    .state_compute(state_compute_stage1),
    .state_done(state_done_stage1),
    .load_initial_values(load_initial_values_stage1),
    .update_bit_position(update_bit_position_stage1),
    .update_parity(update_parity_stage1),
    .state(state_stage1),
    .valid(valid)
  );
  
  // Stage 2: Bit counter
  bit_counter u_bit_counter (
    .clk(clk),
    .rst(rst),
    .load_initial_values(load_initial_values_stage1),
    .update_bit_position(update_bit_position_stage1),
    .bit_pos(bit_pos_stage2),
    .compute_done(compute_done_stage2)
  );
  
  // Stage 3: Parity calculator
  parity_calculator u_parity_calculator (
    .clk(clk),
    .rst(rst),
    .load_initial_values(load_initial_values_stage1),
    .update_parity(update_parity_stage1),
    .bit_pos(bit_pos_stage2),
    .data_in(data_in),
    .compute_done(compute_done_stage2),
    .parity_bit(parity_bit_stage3)
  );
  
  // Output assignment
  assign parity_bit = parity_bit_stage3;
  
endmodule

module state_decoder (
  input [1:0] state,
  output state_idle, state_compute, state_done
);
  localparam IDLE = 2'b00, COMPUTE = 2'b01, DONE = 2'b10;
  
  assign state_idle = (state == IDLE);
  assign state_compute = (state == COMPUTE);
  assign state_done = (state == DONE);
endmodule

module control_unit (
  input clk, rst, start,
  input compute_done,
  input state_idle, state_compute, state_done,
  output reg load_initial_values,
  output reg update_bit_position,
  output reg update_parity,
  output reg [1:0] state,
  output reg valid
);
  localparam IDLE = 2'b00, COMPUTE = 2'b01, DONE = 2'b10;
  
  reg [1:0] next_state;
  reg load_initial_values_next;
  reg update_bit_position_next;
  reg update_parity_next;
  
  always @(*) begin
    next_state = state;
    load_initial_values_next = 1'b0;
    update_bit_position_next = 1'b0;
    update_parity_next = 1'b0;
    
    case (1'b1)
      state_idle: begin
        if (start) begin
          next_state = COMPUTE;
          load_initial_values_next = 1'b1;
        end
      end
      
      state_compute: begin
        update_bit_position_next = ~compute_done;
        update_parity_next = 1'b1;
        if (compute_done) begin
          next_state = DONE;
        end
      end
      
      state_done: begin
        next_state = IDLE;
      end
    endcase
  end
  
  always @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
      valid <= 1'b0;
      load_initial_values <= 1'b0;
      update_bit_position <= 1'b0;
      update_parity <= 1'b0;
    end else begin
      state <= next_state;
      valid <= state_done;
      load_initial_values <= load_initial_values_next;
      update_bit_position <= update_bit_position_next;
      update_parity <= update_parity_next;
    end
  end
endmodule

module bit_counter (
  input clk, rst,
  input load_initial_values,
  input update_bit_position,
  output reg [3:0] bit_pos,
  output compute_done
);
  reg [3:0] bit_pos_next;
  
  assign compute_done = (bit_pos == 4'd15);
  
  always @(*) begin
    bit_pos_next = bit_pos;
    if (load_initial_values) begin
      bit_pos_next = 4'd0;
    end else if (update_bit_position) begin
      bit_pos_next = bit_pos + 4'd1;
    end
  end
  
  always @(posedge clk) begin
    if (rst) begin
      bit_pos <= 4'd0;
    end else begin
      bit_pos <= bit_pos_next;
    end
  end
endmodule

module parity_calculator (
  input clk, rst,
  input load_initial_values,
  input update_parity,
  input [3:0] bit_pos,
  input [15:0] data_in,
  input compute_done,
  output reg parity_bit
);
  reg parity_bit_next;
  
  always @(*) begin
    parity_bit_next = parity_bit;
    if (load_initial_values) begin
      parity_bit_next = 1'b0;
    end else if (update_parity) begin
      parity_bit_next = parity_bit ^ data_in[bit_pos];
    end
  end
  
  always @(posedge clk) begin
    if (rst) begin
      parity_bit <= 1'b0;
    end else begin
      parity_bit <= parity_bit_next;
    end
  end
endmodule