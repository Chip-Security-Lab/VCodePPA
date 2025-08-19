//SystemVerilog
module multi_stage_arith_shifter_valid_ready #(
  parameter DATA_WIDTH = 16,
  parameter SHIFT_WIDTH = 4
)(
  input                          clk,
  input                          rst_n,
  input  [DATA_WIDTH-1:0]        in_value,
  input  [SHIFT_WIDTH-1:0]       shift_amount,
  input                          in_valid,
  output                         in_ready,
  output [DATA_WIDTH-1:0]        out_value,
  output                         out_valid,
  input                          out_ready
);

  // Internal registers for handshake and pipeline
  reg [DATA_WIDTH-1:0] in_value_reg;
  reg [SHIFT_WIDTH-1:0] shift_amount_reg;
  reg                   data_valid_reg;
  reg                   data_valid_next;

  // Fanout buffer registers for high-fanout signals
  reg                   out_ready_buf1, out_ready_buf2;
  reg [DATA_WIDTH-1:0]  in_value_reg_buf1, in_value_reg_buf2;
  reg [SHIFT_WIDTH-1:0] shift_amount_reg_buf1, shift_amount_reg_buf2;
  reg                   data_valid_reg_buf1, data_valid_reg_buf2;
  reg [DATA_WIDTH-1:0]  stage1_buf1, stage1_buf2;

  // Valid-Ready input handshake (buffered)
  assign in_ready = !data_valid_reg_buf2 || (out_ready_buf2 && data_valid_reg_buf2);

  // Buffer out_ready to reduce fanout
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_ready_buf1 <= 1'b0;
      out_ready_buf2 <= 1'b0;
    end else begin
      out_ready_buf1 <= out_ready;
      out_ready_buf2 <= out_ready_buf1;
    end
  end

  // Buffer data_valid_reg to reduce fanout
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_valid_reg_buf1 <= 1'b0;
      data_valid_reg_buf2 <= 1'b0;
    end else begin
      data_valid_reg_buf1 <= data_valid_reg;
      data_valid_reg_buf2 <= data_valid_reg_buf1;
    end
  end

  // Buffer in_value_reg to reduce fanout
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      in_value_reg_buf1 <= {DATA_WIDTH{1'b0}};
      in_value_reg_buf2 <= {DATA_WIDTH{1'b0}};
    end else begin
      in_value_reg_buf1 <= in_value_reg;
      in_value_reg_buf2 <= in_value_reg_buf1;
    end
  end

  // Buffer shift_amount_reg to reduce fanout
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_amount_reg_buf1 <= {SHIFT_WIDTH{1'b0}};
      shift_amount_reg_buf2 <= {SHIFT_WIDTH{1'b0}};
    end else begin
      shift_amount_reg_buf1 <= shift_amount_reg;
      shift_amount_reg_buf2 <= shift_amount_reg_buf1;
    end
  end

  // Valid-Ready register logic (pipelined)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      in_value_reg      <= {DATA_WIDTH{1'b0}};
      shift_amount_reg  <= {SHIFT_WIDTH{1'b0}};
      data_valid_reg    <= 1'b0;
    end else if (in_ready) begin
      if (in_valid) begin
        in_value_reg      <= in_value;
        shift_amount_reg  <= shift_amount;
        data_valid_reg    <= 1'b1;
      end else if (out_ready_buf2 && data_valid_reg_buf2) begin
        data_valid_reg    <= 1'b0;
      end
    end else if (out_ready_buf2 && data_valid_reg_buf2) begin
      data_valid_reg      <= 1'b0;
    end
  end

  // Shift operation pipeline (buffered)
  wire [DATA_WIDTH-1:0] stage1_wire;
  wire [DATA_WIDTH-1:0] stage2_wire;
  reg  [DATA_WIDTH-1:0] stage3_reg;

  // Buffer stage1 to reduce fanout
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1_buf1 <= {DATA_WIDTH{1'b0}};
      stage1_buf2 <= {DATA_WIDTH{1'b0}};
    end else begin
      stage1_buf1 <= stage1_wire;
      stage1_buf2 <= stage1_buf1;
    end
  end

  assign stage1_wire = shift_amount_reg_buf2[3] ? {{8{in_value_reg_buf2[15]}}, in_value_reg_buf2[15:8]} : in_value_reg_buf2;
  assign stage2_wire = shift_amount_reg_buf2[2] ? {{4{stage1_buf2[15]}}, stage1_buf2[15:4]} : stage1_buf2;

  always @(*) begin
    case (shift_amount_reg_buf2[1:0])
      2'b00: stage3_reg = stage2_wire;
      2'b01: stage3_reg = {{1{stage2_wire[15]}}, stage2_wire[15:1]};
      2'b10: stage3_reg = {{2{stage2_wire[15]}}, stage2_wire[15:2]};
      2'b11: stage3_reg = {{3{stage2_wire[15]}}, stage2_wire[15:3]};
      default: stage3_reg = stage2_wire;
    endcase
  end

  // Output valid and data (buffered)
  assign out_value = stage3_reg;
  assign out_valid = data_valid_reg_buf2;

endmodule