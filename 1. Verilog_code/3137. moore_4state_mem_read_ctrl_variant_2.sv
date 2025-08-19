//SystemVerilog
module moore_4state_mem_read_ctrl #(parameter ADDR_WIDTH = 4)(
  input  clk,
  input  rst,
  input  start,
  output reg read_en,
  output reg done,
  output reg [ADDR_WIDTH-1:0] addr
);
  reg [1:0] state, next_state;
  localparam IDLE     = 2'b00,
             SET_ADDR = 2'b01,
             READ_WAIT= 2'b10,
             COMPLETE = 2'b11;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= IDLE; 
      addr  <= 0;
      read_en <= 1'b0;
      done <= 1'b0;
    end else begin
      state <= next_state;
      if (state == SET_ADDR) addr <= addr + 1;
    end
  end

  always @* begin
    // Default output values
    read_en = 1'b0;
    done    = 1'b0;

    // Optimized state transition logic
    case (state)
      IDLE:     next_state = start ? SET_ADDR : IDLE;
      SET_ADDR: next_state = READ_WAIT;
      READ_WAIT:next_state = COMPLETE;
      COMPLETE: begin
                  done = 1'b1;
                  next_state = IDLE;
                end
    endcase
  end
endmodule