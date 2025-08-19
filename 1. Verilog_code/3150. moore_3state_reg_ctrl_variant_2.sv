//SystemVerilog
module moore_3state_reg_ctrl #(parameter WIDTH = 8)(
  input  clk,
  input  rst,
  input  start,
  input  [WIDTH-1:0] din,
  output reg [WIDTH-1:0] dout
);

  // Pipeline stage definitions
  localparam STAGE_COUNT = 3;
  
  // State definitions
  localparam HOLD  = 2'b00,
             LOAD  = 2'b01,
             CLEAR = 2'b10;
  
  // Pipeline registers for state
  reg [1:0] state_stage1, state_stage2, state_stage3;
  reg [1:0] next_state_stage1, next_state_stage2, next_state_stage3;
  
  // Pipeline valid signals
  reg valid_stage1, valid_stage2, valid_stage3;
  
  // Pipeline data registers
  reg [WIDTH-1:0] din_stage1, din_stage2, din_stage3;
  
  // Stage 1: State transition logic
  always @* begin
    case (state_stage1)
      HOLD:  next_state_stage1 = start ? LOAD : HOLD;
      LOAD:  next_state_stage1 = CLEAR;
      CLEAR: next_state_stage1 = HOLD;
      default: next_state_stage1 = HOLD;
    endcase
  end

  // Stage 1: Input data and valid signal processing
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      valid_stage1 <= 1'b0;
      din_stage1 <= {WIDTH{1'b0}};
    end else begin
      valid_stage1 <= 1'b1;
      din_stage1 <= din;
    end
  end

  // Stage 1: State register update
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= HOLD;
    end else begin
      state_stage1 <= next_state_stage1;
    end
  end

  // Stage 2: Pipeline transfer
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage2 <= HOLD;
      next_state_stage2 <= HOLD;
      valid_stage2 <= 1'b0;
      din_stage2 <= {WIDTH{1'b0}};
    end else begin
      state_stage2 <= state_stage1;
      next_state_stage2 <= next_state_stage1;
      valid_stage2 <= valid_stage1;
      din_stage2 <= din_stage1;
    end
  end

  // Stage 3: Pipeline transfer
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage3 <= HOLD;
      next_state_stage3 <= HOLD;
      valid_stage3 <= 1'b0;
      din_stage3 <= {WIDTH{1'b0}};
    end else begin
      state_stage3 <= state_stage2;
      next_state_stage3 <= next_state_stage2;
      valid_stage3 <= valid_stage2;
      din_stage3 <= din_stage2;
    end
  end

  // Output logic
  reg [WIDTH-1:0] dout_next;
  always @* begin
    dout_next = dout;
    if (valid_stage3) begin
      case (state_stage3)
        LOAD:  dout_next = din_stage3;
        CLEAR: dout_next = 0;
        default: dout_next = dout;
      endcase
    end
  end

  // Output register update
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      dout <= {WIDTH{1'b0}};
    end else begin
      dout <= dout_next;
    end
  end

endmodule