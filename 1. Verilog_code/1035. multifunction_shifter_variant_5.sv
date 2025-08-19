//SystemVerilog
module multifunction_shifter_valid_ready (
  input              clk,
  input              rst_n,
  input      [31:0]  operand_in,
  input      [4:0]   shift_amt_in,
  input      [1:0]   operation_in, // 00=logical, 01=arithmetic, 10=rotate, 11=special
  input              valid_in,
  output reg         ready_in,
  output reg [31:0]  shifted_out,
  output reg         valid_out,
  input              ready_out
);

  reg [31:0] operand_reg;
  reg [4:0]  shift_amt_reg;
  reg [1:0]  operation_reg;
  reg        data_valid;

  reg [31:0] shifted_next;
  reg        valid_next;

  // Move register before combinational logic (retiming)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      operand_reg   <= 32'b0;
      shift_amt_reg <= 5'b0;
      operation_reg <= 2'b0;
      data_valid    <= 1'b0;
      valid_next    <= 1'b0;
    end else begin
      if (valid_in && ready_in) begin
        operand_reg   <= operand_in;
        shift_amt_reg <= shift_amt_in;
        operation_reg <= operation_in;
        data_valid    <= 1'b1;
        valid_next    <= 1'b1;
      end else if (valid_out && ready_out) begin
        data_valid    <= 1'b0;
        valid_next    <= 1'b0;
      end
    end
  end

  // Combinational logic for shifted result
  always @(*) begin
    case (operation_reg)
      2'b00: shifted_next = operand_reg >> shift_amt_reg;     // Logical right
      2'b01: shifted_next = $signed(operand_reg) >>> shift_amt_reg; // Arithmetic right
      2'b10: shifted_next = {operand_reg, operand_reg} >> shift_amt_reg; // Rotate right
      2'b11: shifted_next = {operand_reg[15:0], operand_reg[31:16]}; // Byte swap
      default: shifted_next = 32'b0;
    endcase
  end

  // Register the output (retimed)
  reg [31:0] shifted_reg;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shifted_reg <= 32'b0;
    end else begin
      if (valid_next && (!valid_out || (valid_out && ready_out))) begin
        shifted_reg <= shifted_next;
      end
    end
  end

  // Output assignments
  always @(*) begin
    ready_in  = (!data_valid) || (valid_out && ready_out);
    valid_out = data_valid;
    shifted_out = shifted_reg;
  end

endmodule