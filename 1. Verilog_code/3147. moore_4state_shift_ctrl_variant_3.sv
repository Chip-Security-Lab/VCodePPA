//SystemVerilog
module moore_4state_shift_ctrl #(parameter COUNT_WIDTH = 4)(
  input  clk,
  input  rst,
  input  start,
  input  [COUNT_WIDTH-1:0] shift_count,
  output reg shift_en,
  output reg done
);
  reg [1:0] state, next_state;
  localparam WAIT    = 2'b00,
             LOAD    = 2'b01,
             SHIFT   = 2'b10,
             DONE_ST = 2'b11;
  reg [COUNT_WIDTH-1:0] counter;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state   <= WAIT;
      counter <= 0;
    end else begin
      state <= next_state;
      if (state == LOAD) begin
        counter <= shift_count;
      end else if (state == SHIFT && counter > 0) begin
        counter <= counter - 1;
      end
    end
  end

  always @* begin
    shift_en = 1'b0;
    done = 1'b0;
    next_state = state; // Default assignment to prevent latches
    
    case (state)
      WAIT: begin
        if (start) begin
          next_state = LOAD;
        end else begin
          next_state = WAIT;
        end
      end
      
      LOAD: begin
        next_state = SHIFT;
      end
      
      SHIFT: begin
        shift_en = 1'b1;
        if (counter == 0) begin
          next_state = DONE_ST;
        end else begin
          next_state = SHIFT;
        end
      end
      
      DONE_ST: begin
        done = 1'b1;
        next_state = WAIT;
      end
    endcase
  end
endmodule