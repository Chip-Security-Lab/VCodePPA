//SystemVerilog
module param_circular_right_shifter #(
  parameter WIDTH = 8
)(
  input  wire [WIDTH-1:0] data,
  input  wire [$clog2(WIDTH)-1:0] rotate,
  output wire [WIDTH-1:0] result
);

  // Pipeline registers for data and rotate control
  reg  [WIDTH-1:0] data_stage1;
  reg  [$clog2(WIDTH)-1:0] rotate_stage1;
  reg  [WIDTH-1:0] rotated_data_stage2;
  reg  [6:0] minuend_stage3;
  reg  [6:0] subtrahend_stage3;
  reg  [6:0] generate_borrow_stage4;
  reg  [6:0] propagate_borrow_stage4;
  reg  [7:0] borrow_chain_stage5;
  reg  [6:0] difference_stage5;
  reg  [WIDTH-1:0] result_stage6;

  // Clock and reset to be added by the user for full pipelining
  // For demonstration, assuming combinational pipeline registers (use clock in actual design)
  // The following always blocks are to be replaced with clocked always_ff in synthesis

  // Stage 1: Register inputs
  always @(*) begin
    data_stage1      = data;
    rotate_stage1    = rotate;
  end

  // Stage 2: Circular right shift
  always @(*) begin
    case (rotate_stage1)
      3'd0: rotated_data_stage2 = data_stage1;
      3'd1: rotated_data_stage2 = {data_stage1[0], data_stage1[WIDTH-1:1]};
      3'd2: rotated_data_stage2 = {data_stage1[1:0], data_stage1[WIDTH-1:2]};
      3'd3: rotated_data_stage2 = {data_stage1[2:0], data_stage1[WIDTH-1:3]};
      3'd4: rotated_data_stage2 = {data_stage1[3:0], data_stage1[WIDTH-1:4]};
      3'd5: rotated_data_stage2 = {data_stage1[4:0], data_stage1[WIDTH-1:5]};
      3'd6: rotated_data_stage2 = {data_stage1[5:0], data_stage1[WIDTH-1:6]};
      3'd7: rotated_data_stage2 = {data_stage1[6:0], data_stage1[WIDTH-1:7]};
      default: rotated_data_stage2 = data_stage1;
    endcase
  end

  // Stage 3: Prepare for borrow calculation
  always @(*) begin
    minuend_stage3    = rotated_data_stage2[6:0];
    subtrahend_stage3 = data_stage1[6:0];
  end

  // Stage 4: Generate and propagate borrow signals
  always @(*) begin
    generate_borrow_stage4  = (~minuend_stage3) & subtrahend_stage3;
    propagate_borrow_stage4 = ~(minuend_stage3 ^ subtrahend_stage3);
  end

  // Stage 5: Borrow chain and difference calculation
  integer i;
  always @(*) begin
    borrow_chain_stage5[0] = 1'b0;
    for (i = 0; i < 7; i = i + 1) begin
      borrow_chain_stage5[i+1] = generate_borrow_stage4[i] | (propagate_borrow_stage4[i] & borrow_chain_stage5[i]);
      difference_stage5[i]     = minuend_stage3[i] ^ subtrahend_stage3[i] ^ borrow_chain_stage5[i];
    end
  end

  // Stage 6: Output register
  always @(*) begin
    result_stage6 = {rotated_data_stage2[7], difference_stage5};
  end

  // Final output
  assign result = result_stage6;

endmodule