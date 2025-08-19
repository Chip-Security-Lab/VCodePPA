//SystemVerilog
module moore_3state_handshake_top(
  input  clk,
  input  rst,
  input  start,
  input  ack,
  output done
);
  wire [1:0] state, next_state;
  
  state_reg state_reg_inst(
    .clk(clk),
    .rst(rst),
    .next_state(next_state),
    .state(state)
  );
  
  next_state_logic next_state_logic_inst(
    .state(state),
    .start(start),
    .ack(ack),
    .next_state(next_state)
  );
  
  output_logic output_logic_inst(
    .state(state),
    .done(done)
  );
endmodule

module state_reg(
  input  clk,
  input  rst,
  input  [1:0] next_state,
  output reg [1:0] state
);
  localparam IDLE     = 2'b00,
             WAIT_ACK = 2'b01,
             COMPLETE = 2'b10;
             
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= IDLE;
    end
    else begin
      state <= next_state;
    end
  end
endmodule

module next_state_logic(
  input  [1:0] state,
  input  start,
  input  ack,
  output reg [1:0] next_state
);
  localparam IDLE     = 2'b00,
             WAIT_ACK = 2'b01,
             COMPLETE = 2'b10;
             
  always @* begin
    case (state)
      IDLE: begin
        if (start) begin
          next_state = WAIT_ACK;
        end
        else begin
          next_state = IDLE;
        end
      end
      
      WAIT_ACK: begin
        if (ack) begin
          next_state = COMPLETE;
        end
        else begin
          next_state = WAIT_ACK;
        end
      end
      
      COMPLETE: begin
        next_state = IDLE;
      end
      
      default: begin
        next_state = IDLE;
      end
    endcase
  end
endmodule

module output_logic(
  input  [1:0] state,
  output reg done
);
  localparam IDLE     = 2'b00,
             WAIT_ACK = 2'b01,
             COMPLETE = 2'b10;
  
  always @* begin
    if (state == COMPLETE) begin
      done = 1'b1;
    end
    else begin
      done = 1'b0;
    end
  end
endmodule