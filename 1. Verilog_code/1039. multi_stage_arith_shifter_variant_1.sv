//SystemVerilog
module multi_stage_arith_shifter_valid_ready #(
  parameter DATA_WIDTH = 16,
  parameter SHIFT_WIDTH = 4
)(
  input                      clk,
  input                      rst_n,
  input  [DATA_WIDTH-1:0]    in_value,
  input  [SHIFT_WIDTH-1:0]   shift_amount,
  input                      in_valid,
  output                     in_ready,
  output [DATA_WIDTH-1:0]    out_value,
  output                     out_valid,
  input                      out_ready
);

  // Internal registers and wires
  reg  [DATA_WIDTH-1:0]  input_data_reg;
  reg  [SHIFT_WIDTH-1:0] shift_reg;
  reg                    input_ready_reg;
  reg                    output_valid_reg;
  reg  [DATA_WIDTH-1:0]  output_data_reg;
  reg  [DATA_WIDTH-1:0]  stage3_reg;

  wire [DATA_WIDTH-1:0]  stage1_wire;
  wire [DATA_WIDTH-1:0]  stage2_wire;
  wire                   input_handshake;
  wire                   output_handshake;

  // Input handshake and ready generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      input_ready_reg <= 1'b1;
    end else begin
      if (input_handshake) begin
        input_ready_reg <= 1'b0;
      end else if (output_handshake) begin
        input_ready_reg <= 1'b1;
      end
    end
  end

  assign in_ready = input_ready_reg;

  assign input_handshake  = in_valid && input_ready_reg;
  assign output_handshake = output_valid_reg && out_ready;

  // Latch input data and shift amount on handshake
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      input_data_reg <= {DATA_WIDTH{1'b0}};
      shift_reg      <= {SHIFT_WIDTH{1'b0}};
    end else if (input_handshake) begin
      input_data_reg <= in_value;
      shift_reg      <= shift_amount;
    end
  end

  // Combinational shift stage 1
  assign stage1_wire = shift_reg[3] ? {{8{input_data_reg[15]}}, input_data_reg[15:8]} : input_data_reg;

  // Combinational shift stage 2
  assign stage2_wire = shift_reg[2] ? {{4{stage1_wire[15]}}, stage1_wire[15:4]} : stage1_wire;

  // Combinational shift stage 3
  always @(*) begin
    case (shift_reg[1:0])
      2'b00: stage3_reg = stage2_wire;
      2'b01: stage3_reg = {{1{stage2_wire[15]}}, stage2_wire[15:1]};
      2'b10: stage3_reg = {{2{stage2_wire[15]}}, stage2_wire[15:2]};
      2'b11: stage3_reg = {{3{stage2_wire[15]}}, stage2_wire[15:3]};
      default: stage3_reg = stage2_wire;
    endcase
  end

  // Output valid and output data register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      output_valid_reg <= 1'b0;
      output_data_reg  <= {DATA_WIDTH{1'b0}};
    end else begin
      if (input_handshake) begin
        output_data_reg  <= stage3_reg;
        output_valid_reg <= 1'b1;
      end else if (output_handshake) begin
        output_valid_reg <= 1'b0;
      end
    end
  end

  assign out_valid = output_valid_reg;
  assign out_value = output_data_reg;

endmodule