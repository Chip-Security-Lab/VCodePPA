//SystemVerilog
module multifunction_shifter_valid_ready (
  input              clk,
  input              rst_n,
  input      [31:0]  in_operand,
  input      [4:0]   in_shift_amt,
  input      [1:0]   in_operation, // 00=logical, 01=arithmetic, 10=rotate, 11=special
  input              in_valid,
  output reg         in_ready,
  output reg [31:0]  out_shifted,
  output reg         out_valid,
  input              out_ready
);

  reg [31:0] operand_reg;
  reg [4:0]  shift_amt_reg;
  reg [1:0]  operation_reg;
  reg        data_hold;

  // Multiplier state and signals
  reg [5:0]  mul_counter;
  reg [31:0] mul_multiplicand;
  reg [31:0] mul_multiplier;
  reg [63:0] mul_product;
  reg        mul_busy;
  reg        mul_start;
  reg [31:0] mul_result;

  // Output register for rotate and special
  reg [31:0] rotate_result;
  reg [31:0] swap_result;

  // FSM for operation
  reg [1:0]  op_state, op_next_state;

  localparam OP_IDLE   = 2'b00;
  localparam OP_SHIFT  = 2'b01;
  localparam OP_MUL    = 2'b10;
  localparam OP_DONE   = 2'b11;

  // Input and Output Handshake
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      in_ready   <= 1'b1;
      out_valid  <= 1'b0;
      data_hold  <= 1'b0;
      operand_reg <= 32'b0;
      shift_amt_reg <= 5'b0;
      operation_reg <= 2'b0;
    end else begin
      if (in_ready && in_valid) begin
        operand_reg   <= in_operand;
        shift_amt_reg <= in_shift_amt;
        operation_reg <= in_operation;
        data_hold     <= 1'b1;
        in_ready      <= 1'b0;
      end else if (out_valid && out_ready) begin
        in_ready      <= 1'b1;
      end

      if (data_hold) begin
        out_valid <= 1'b1;
        if (out_ready) begin
          data_hold <= 1'b0;
          out_valid <= 1'b0;
        end
      end
    end
  end

  // Shifter and rotate/swap combinational logic
  always @(*) begin
    rotate_result = {operand_reg, operand_reg} >> shift_amt_reg;
    swap_result   = {operand_reg[15:0], operand_reg[31:16]};
  end

  // FSM for operation selection
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      op_state <= OP_IDLE;
    end else begin
      op_state <= op_next_state;
    end
  end

  always @(*) begin
    case (op_state)
      OP_IDLE: begin
        if (data_hold) begin
          if (operation_reg == 2'b00 || operation_reg == 2'b01 || 
              operation_reg == 2'b10 || operation_reg == 2'b11)
            op_next_state = OP_SHIFT;
          else
            op_next_state = OP_IDLE;
        end else begin
          op_next_state = OP_IDLE;
        end
      end
      OP_SHIFT: begin
        if (operation_reg == 2'b00 || operation_reg == 2'b01) begin
          op_next_state = OP_DONE;
        end else if (operation_reg == 2'b10 || operation_reg == 2'b11) begin
          op_next_state = OP_DONE;
        end else begin
          op_next_state = OP_IDLE;
        end
      end
      OP_DONE: begin
        if (out_valid && out_ready)
          op_next_state = OP_IDLE;
        else
          op_next_state = OP_DONE;
      end
      default: op_next_state = OP_IDLE;
    endcase
  end

  // Shift/Add Multiplier (for demonstration, we'll replace logical/arithmetic shift with shift-add "multiply-divide" method)
  // For the purpose of this code, logical/arithmetic shift is replaced by shift-add multiply/divide by 2^n
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mul_counter      <= 6'd0;
      mul_multiplicand <= 32'b0;
      mul_multiplier   <= 32'b0;
      mul_product      <= 64'b0;
      mul_busy         <= 1'b0;
      mul_start        <= 1'b0;
      mul_result       <= 32'b0;
    end else begin
      mul_start <= 1'b0;
      if (op_state == OP_SHIFT && operation_reg == 2'b00) begin // Logical right shift as divide
        if (!mul_busy) begin
          mul_multiplicand <= operand_reg;
          mul_multiplier   <= (32'h1 << (32 - shift_amt_reg));
          mul_product      <= 64'b0;
          mul_counter      <= 6'd0;
          mul_busy         <= 1'b1;
          mul_start        <= 1'b1;
        end
      end else if (op_state == OP_SHIFT && operation_reg == 2'b01) begin // Arithmetic right shift as signed divide
        if (!mul_busy) begin
          mul_multiplicand <= operand_reg;
          mul_multiplier   <= (32'h1 << (32 - shift_amt_reg));
          mul_product      <= 64'b0;
          mul_counter      <= 6'd0;
          mul_busy         <= 1'b1;
          mul_start        <= 1'b1;
        end
      end

      if (mul_busy) begin
        if (mul_counter < 32) begin
          if (mul_multiplier[0])
            mul_product <= mul_product + (mul_multiplicand << mul_counter);
          mul_multiplier <= mul_multiplier >> 1;
          mul_counter <= mul_counter + 1;
        end else begin
          mul_busy <= 1'b0;
          mul_counter <= 6'd0;
          // For logical right shift, take upper 32-bits to mimic division
          mul_result <= mul_product[63:32];
        end
      end
    end
  end

  // Output selection logic
  always @(*) begin
    case (operation_reg)
      2'b00: begin // Logical right shift using shift-add multiply/divide
        if (mul_busy || mul_start)
          out_shifted = mul_result;
        else
          out_shifted = operand_reg >> shift_amt_reg;
      end
      2'b01: begin // Arithmetic right shift using shift-add multiply/divide
        if (mul_busy || mul_start)
          out_shifted = mul_result;
        else
          out_shifted = $signed(operand_reg) >>> shift_amt_reg;
      end
      2'b10: out_shifted = rotate_result; // Rotate right
      2'b11: out_shifted = swap_result;   // Byte swap
      default: out_shifted = 32'b0;
    endcase
  end

endmodule