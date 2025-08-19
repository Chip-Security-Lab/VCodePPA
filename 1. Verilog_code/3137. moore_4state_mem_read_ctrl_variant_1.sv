//SystemVerilog
module moore_4state_mem_read_ctrl #(parameter ADDR_WIDTH = 4)(
  input  clk,
  input  rst,
  input  start,
  output reg read_en,
  output reg done,
  output reg [ADDR_WIDTH-1:0] addr
);
  // Define states with meaningful names and one-hot encoding for better timing
  localparam [3:0] IDLE     = 4'b0001,
                   SET_ADDR = 4'b0010,
                   READ_WAIT= 4'b0100,
                   COMPLETE = 4'b1000;
                   
  // State registers - current and next (one-hot encoded)
  reg [3:0] current_state, next_state;
  
  // Pipeline registers for improved timing
  reg start_r, start_r2;
  reg addr_update_en;
  reg read_en_pre;
  reg done_pre;
  
  // Double-register start input to reduce input path delay
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      start_r <= 1'b0;
      start_r2 <= 1'b0;
    end else begin
      start_r <= start;
      start_r2 <= start_r;
    end
  end
  
  // State register update
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end
  
  // Simplified state transition logic with reduced critical path
  // Separate condition checks for parallel evaluation
  wire idle_to_set_addr = current_state[0] & start_r2;
  wire set_to_read = current_state[1];
  wire read_to_complete = current_state[2];
  wire complete_to_idle = current_state[3];
  
  // Pre-compute control signals based on current state only
  always @* begin
    // Default values
    addr_update_en = idle_to_set_addr;
    read_en_pre = set_to_read;
    done_pre = complete_to_idle;
    
    // Next state logic - simplified using one-hot encoding properties
    next_state[0] = (current_state[0] & ~start_r2) | complete_to_idle;
    next_state[1] = idle_to_set_addr;
    next_state[2] = set_to_read;
    next_state[3] = read_to_complete;
  end
  
  // Address counter logic - with enable signal optimization
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      addr <= {ADDR_WIDTH{1'b0}};
    end else if (addr_update_en) begin
      addr <= addr + 1'b1;
    end
  end
  
  // Output registers - pipelined for better timing
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      read_en <= 1'b0;
      done <= 1'b0;
    end else begin
      read_en <= read_en_pre;
      done <= done_pre;
    end
  end
endmodule