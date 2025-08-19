//SystemVerilog
module moore_3state_mem_write_ctrl_pipelined #(parameter ADDR_WIDTH = 4)(
  input  clk,
  input  rst,
  input  start,
  output reg we,
  output reg [ADDR_WIDTH-1:0] addr
);

  // State definitions
  localparam IDLE     = 2'b00,
             SET_ADDR = 2'b01,
             WRITE    = 2'b10;

  // Pipeline stages
  reg [1:0] state_stage1, state_stage2, state_stage3;
  reg [ADDR_WIDTH-1:0] addr_stage1, addr_stage2, addr_stage3;
  reg valid_stage1, valid_stage2, valid_stage3;
  reg start_stage1, start_stage2;
  
  // Pipeline stage 1: IDLE state
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= IDLE;
      addr_stage1 <= 0;
      valid_stage1 <= 0;
      start_stage1 <= 0;
    end else begin
      state_stage1 <= IDLE;
      addr_stage1 <= addr_stage3;
      valid_stage1 <= 1'b1;
      start_stage1 <= start;
    end
  end
  
  // Pipeline stage 2: SET_ADDR state
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage2 <= IDLE;
      addr_stage2 <= 0;
      valid_stage2 <= 0;
      start_stage2 <= 0;
    end else begin
      if (valid_stage1 && start_stage1) begin
        state_stage2 <= SET_ADDR;
        addr_stage2 <= addr_stage1 + 1;
        valid_stage2 <= 1'b1;
      end else begin
        state_stage2 <= IDLE;
        addr_stage2 <= addr_stage1;
        valid_stage2 <= valid_stage1;
      end
      start_stage2 <= start_stage1;
    end
  end
  
  // Pipeline stage 3: WRITE state
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage3 <= IDLE;
      addr_stage3 <= 0;
      valid_stage3 <= 0;
    end else begin
      if (valid_stage2 && state_stage2 == SET_ADDR) begin
        state_stage3 <= WRITE;
        addr_stage3 <= addr_stage2;
        valid_stage3 <= 1'b1;
      end else begin
        state_stage3 <= IDLE;
        addr_stage3 <= addr_stage2;
        valid_stage3 <= valid_stage2;
      end
    end
  end
  
  // Output logic
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      we <= 0;
      addr <= 0;
    end else begin
      we <= (state_stage3 == WRITE) && valid_stage3;
      addr <= addr_stage3;
    end
  end

endmodule