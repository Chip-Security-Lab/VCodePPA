//SystemVerilog
module moore_3state_mem_write_ctrl_pipeline #(parameter ADDR_WIDTH = 4)(
  input  clk,
  input  rst,
  input  start,
  output reg we,
  output reg [ADDR_WIDTH-1:0] addr
);
  reg [1:0] state_stage1, state_stage2, next_state_stage1, next_state_stage2;
  reg [ADDR_WIDTH-1:0] addr_stage1, addr_stage2;
  
  localparam IDLE    = 2'b00,
             SET_ADDR= 2'b01,
             WRITE   = 2'b10;

  // Stage 1: State Register
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= IDLE;
      addr_stage1  <= 0;
    end else begin
      state_stage1 <= next_state_stage1;
      addr_stage1 <= (state_stage1 == SET_ADDR) ? (addr_stage1 + 1) : addr_stage1;
    end
  end

  // Stage 2: Next State Logic
  always @* begin
    we = (state_stage2 == WRITE) ? 1'b1 : 1'b0;
    next_state_stage1 = state_stage1; // Default state
    if (state_stage1 == IDLE && start) begin
      next_state_stage1 = SET_ADDR;
    end else if (state_stage1 == SET_ADDR) begin
      next_state_stage1 = WRITE;
    end else begin
      next_state_stage1 = IDLE;
    end
  end

  // Stage 2: State Register
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage2 <= IDLE;
      addr_stage2  <= 0;
    end else begin
      state_stage2 <= next_state_stage1;
      addr_stage2 <= addr_stage1; // Forwarding the address
    end
  end

  // Control Logic for Pipeline
  always @* begin
    if (state_stage2 == WRITE) begin
      addr = addr_stage2;
    end else begin
      addr = addr_stage1; // Default to stage 1 address
    end
  end

endmodule