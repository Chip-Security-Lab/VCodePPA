//SystemVerilog
module moore_4state_mem_read_ctrl #(parameter ADDR_WIDTH = 4)(
  input  clk,
  input  rst,
  input  start,
  output reg read_en,
  output reg done,
  output reg [ADDR_WIDTH-1:0] addr
);

  // Pipeline stage registers
  reg [1:0] state_stage1, state_stage2, state_stage3;
  reg [ADDR_WIDTH-1:0] addr_stage1, addr_stage2;
  reg start_stage1, start_stage2;
  reg read_en_stage1, read_en_stage2;
  reg done_stage1, done_stage2;

  // State definitions
  localparam IDLE     = 2'b00,
             SET_ADDR = 2'b01,
             READ_WAIT= 2'b10,
             COMPLETE = 2'b11;

  // Stage 1: Address Generation
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= IDLE;
      addr_stage1 <= 0;
      start_stage1 <= 0;
    end else begin
      if (state_stage1 == IDLE) begin
        if (start) begin
          state_stage1 <= SET_ADDR;
        end else begin
          state_stage1 <= IDLE;
        end
      end else if (state_stage1 == SET_ADDR) begin
        state_stage1 <= READ_WAIT;
      end else if (state_stage1 == READ_WAIT) begin
        state_stage1 <= COMPLETE;
      end else begin
        state_stage1 <= IDLE;
      end
      
      if (state_stage1 == SET_ADDR) 
        addr_stage1 <= addr_stage1 + 1;
      
      start_stage1 <= start;
    end
  end

  // Stage 2: Read Control
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage2 <= IDLE;
      addr_stage2 <= 0;
      read_en_stage1 <= 0;
      start_stage2 <= 0;
    end else begin
      state_stage2 <= state_stage1;
      addr_stage2 <= addr_stage1;
      if (state_stage1 == READ_WAIT) begin
        read_en_stage1 <= 1;
      end else begin
        read_en_stage1 <= 0;
      end
      start_stage2 <= start_stage1;
    end
  end

  // Stage 3: Completion
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage3 <= IDLE;
      read_en <= 0;
      done_stage1 <= 0;
    end else begin
      state_stage3 <= state_stage2;
      read_en <= read_en_stage1;
      if (state_stage2 == COMPLETE) begin
        done_stage1 <= 1;
      end else begin
        done_stage1 <= 0;
      end
    end
  end

  // Output stage
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      done <= 0;
      addr <= 0;
    end else begin
      done <= done_stage1;
      addr <= addr_stage2;
    end
  end

endmodule