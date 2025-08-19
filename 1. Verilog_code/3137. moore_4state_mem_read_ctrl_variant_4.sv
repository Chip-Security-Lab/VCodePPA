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

  // State register
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  // Address counter logic
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      addr <= {ADDR_WIDTH{1'b0}};
    end else if (state == SET_ADDR) begin
      addr <= addr + 1'b1;
    end
  end

  // Next state logic
  always @* begin
    case (state)
      IDLE:      next_state = start ? SET_ADDR : IDLE;
      SET_ADDR:  next_state = READ_WAIT;
      READ_WAIT: next_state = COMPLETE;
      COMPLETE:  next_state = IDLE;
      default:   next_state = IDLE;
    endcase
  end

  // Output logic
  always @* begin
    // Default values
    read_en = 1'b0;
    done = 1'b0;
    
    case (state)
      SET_ADDR:  read_en = 1'b1;
      COMPLETE:  done = 1'b1;
    endcase
  end
endmodule